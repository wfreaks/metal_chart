//
//  MetalChart.m
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/09.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "MetalChart.h"
#import "Buffers.h"
#import "NSArray+Utility.h"

@interface FMDimensionalProjection()


@end


@interface FMSpatialProjection()

@property (strong, nonatomic) NSArray<FMDimensionalProjection *> * _Nonnull dimensions;
@property (strong, nonatomic) UniformProjection * _Nonnull projection;

@end


@interface MetalChart()

@property (strong, nonatomic) NSArray<id<FMRenderable>> *series;
@property (strong, nonatomic) NSArray<FMSpatialProjection *> *projections;
@property (strong, nonatomic) NSSet<FMSpatialProjection *> *projectionSet;

@property (strong, nonatomic) NSArray<id<FMAttachment>> *preRenderables;
@property (strong, nonatomic) NSArray<id<FMAttachment>> *postRenderables;

@property (strong, nonatomic) dispatch_semaphore_t semaphore;

@end

@implementation FMDimensionalProjection

- (instancetype)initWithDimensionId:(NSInteger)dimId minValue:(CGFloat)min maxValue:(CGFloat)max
{
	self = [super init];
	if(self) {
		_dimensionId = dimId;
		_min = min;
		_max = max;
	}
	return self;
}

- (void)setMin:(CGFloat)min
{
	void (^ willUpdate)(CGFloat * _Nullable, CGFloat * _Nullable) = _willUpdate;
	if(willUpdate != nil) {
		willUpdate(&min, nil);
	}
	_min = min;
}

- (void)setMax:(CGFloat)max
{
	void (^ willUpdate)(CGFloat * _Nullable, CGFloat * _Nullable) = _willUpdate;
	if(willUpdate != nil) {
		willUpdate(nil, &max);
	}
	_max = max;
}

- (void)setMin:(CGFloat)min max:(CGFloat)max
{
	void (^ willUpdate)(CGFloat * _Nullable, CGFloat * _Nullable) = _willUpdate;
	if(willUpdate != nil) {
		willUpdate(&min, &max);
	}
	_min = min;
	_max = max;
}

- (CGFloat)length { return _max - _min; }

- (CGFloat)mid { return 0.5 * (_min + _max); }

- (CGFloat)convertValue:(CGFloat)value
                     to:(FMDimensionalProjection *)to
{
    const CGFloat v = (value - _min) / self.length;
    return (to.length * v) + to.min;
}

@end


@implementation FMSpatialProjection

- (instancetype)initWithDimensions:(NSArray<FMDimensionalProjection *> *)dimensions
{
	self = [super init];
	if(self) {
		_dimensions = [NSArray arrayWithArray:dimensions];
		_projection = [[UniformProjection alloc] initWithResource:[DeviceResource defaultResource]];
	}
	return self;
}

- (NSUInteger)rank
{
	return _dimensions.count;
}

- (void)writeToBuffer
{
	FMDimensionalProjection *xDim = _dimensions[0];
	FMDimensionalProjection *yDim = _dimensions[1];
	[_projection setValueScale:CGSizeMake((xDim.max-xDim.min)/2, (yDim.max-yDim.min)/2)];
	[_projection setValueOffset:CGSizeMake(-(xDim.max+xDim.min)/2, -(yDim.max+yDim.min)/2)];
}

- (FMDimensionalProjection *)dimensionWithId:(NSInteger)dimensionId
{
	for(FMDimensionalProjection *p in _dimensions) {
		if(p.dimensionId == dimensionId) return p;
	}
	return nil;
}

- (void)configure:(MTKView *)view padding:(RectPadding)padding
{
	[_projection setPhysicalSize:view.bounds.size];
	[_projection setSampleCount:view.sampleCount];
	[_projection setColorPixelFormat:view.colorPixelFormat];
	[_projection setPadding:padding];
}

- (BOOL)matchesDimensionIds:(NSArray<NSNumber *> *)ids
{
	const NSInteger count = _dimensions.count;
	BOOL r = NO;
	if(count == ids.count) {
		for(NSInteger i = 0; i < count; ++i) {
			if(_dimensions[i].dimensionId != ids[i].integerValue) {
				return NO;
			}
		}
		r = YES;
	}
	return r;
}

@end


@implementation MetalChart

- (instancetype)init
{
	self = [super init];
	if(self) {
		_series = [NSArray array];
		_projections = [NSArray array];
		_projectionSet = [NSSet set];
		_preRenderables = [NSArray array];
		_postRenderables = [NSArray array];
		_semaphore = dispatch_semaphore_create(1);
        _clearDepth = 0;
	}
	return self;
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
	// 描画前にバッファへ書き込むのでここは無視する.
}

// かなり長く見えるが、同期を短くしたり分岐を整理するためだけの行が多い. 大雑把に言って、
// ・semaphore_wait 前は 各配列を破綻しないようキャプチャ / projectionの更新
// ・semaphore_wait 内では preRenderable / series / postRenderable を描画
// ・semaphore_signale 後は レンダリング結果をキューに入れてコミット
// という流れになる. 実際サブルーチン化してリファクタリングするのは容易である.
- (void)drawInMTKView:(MTKView *)view
{
    view.clearDepth = self.clearDepth;
    
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    
	void (^willDraw)(MetalChart * _Nonnull) = _willDraw;
	if(willDraw != nil) willDraw(self);
	
	NSArray<id<FMRenderable>> *seriesArray = nil;
	NSArray<FMSpatialProjection *> *projectionArray = nil;
	NSArray<id<FMAttachment>> *preRenderables = nil;
	NSArray<id<FMAttachment>> *postRenderables = nil;
    id<FMCommandBufferHook> hook = nil;
	
	@synchronized(self) {
		seriesArray = _series;
		projectionArray = _projections;
		preRenderables = _preRenderables;
		postRenderables = _postRenderables;
        hook = _bufferHook;
	}
	
	for(FMSpatialProjection *projection in _projectionSet) {
		[projection configure:view padding:_padding];
		[projection writeToBuffer];
	}
	
	id<MTLCommandBuffer> buffer = nil;
	id<MTLDrawable> drawable = nil;
	
	MTLRenderPassDescriptor *pass = view.currentRenderPassDescriptor;
	if(pass) {
		drawable = view.currentDrawable;
		if(drawable) {
			buffer = [[DeviceResource defaultResource].queue commandBuffer];
            
            [hook chart:self willStartEncodingToBuffer:buffer];
            
			id<MTLRenderCommandEncoder> encoder = [buffer renderCommandEncoderWithDescriptor:pass];
			
			for(id<FMAttachment> renderable in preRenderables) {
				[renderable encodeWith:encoder chart:self view:view];
			}
			
            const RectPadding pad = _padding;
            const CGFloat scale = [UIScreen mainScreen].scale;
            const CGSize size = view.bounds.size;
            const NSUInteger w  = size.width * scale, h = size.height * scale;
            const NSUInteger l = pad.left * scale, r = pad.right * scale;
            const NSUInteger t = pad.top * scale, b = pad.bottom * scale;
            
            const MTLScissorRect padRect = {l, t, w-(l+r), h-(t+b)};
            [encoder setScissorRect:padRect];
            
			const NSUInteger count = seriesArray.count;
			for(NSUInteger i = 0; i < count; ++i) {
				id<FMRenderable> series = seriesArray[i];
				FMSpatialProjection *projection = projectionArray[i];
				[series encodeWith:encoder projection:projection.projection];
			}
            const MTLScissorRect orgRect = {0, 0, w, h};
            [encoder setScissorRect:orgRect];
			
			for(id<FMAttachment> renderable in postRenderables) {
				[renderable encodeWith:encoder chart:self view:view];
			}
			
			[encoder endEncoding];
            
            [hook chart:self willCommitBuffer:buffer];
		}
	}
	
    void (^didDraw)(MetalChart * _Nonnull) = _didDraw;
    if(didDraw != nil) didDraw(self);
    
	if(drawable) {
		__block dispatch_semaphore_t semaphore = _semaphore;
		[buffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull buffer) {
			dispatch_semaphore_signal(semaphore);
		}];
		[buffer presentDrawable:drawable];
		[buffer commit];
	} else {
		dispatch_semaphore_signal(_semaphore);
	}
	
}

- (void)addSeries:(id<FMRenderable>)series projection:(FMSpatialProjection *)projection
{
	@synchronized(self) {
		if(![_series containsObject:series]) {
			_projectionSet = [_projectionSet setByAddingObject:projection];
			_projections = [_projections arrayByAddingObject:projection];
			_series = [_series arrayByAddingObject:series];
            if([series conformsToProtocol:@protocol(FMDepthClient)]) {
                [self reconstructDepthClients];
            }
		}
	}
}

- (void)addSeriesArray:(NSArray<id<FMRenderable>> *)series
		   projections:(NSArray<FMSpatialProjection *> *)projections
{
	if(series.count == projections.count) {
		const NSInteger count = series.count;
		@synchronized(self) {
			for(NSInteger i = 0; i < count; ++i) {
				[self addSeries:series[i] projection:projections[i]];
			}
		}
	}
}

// immutableなcollectionを使ってるので非常にまどろっこしいが、描画サイクルの度に
// 防御的コピーを強制されるならこちらの方がよほどパフォーマンス的にはまともだと思われる
- (void)removeSeries:(id<FMRenderable>)series
{
	@synchronized(self) {
		const NSUInteger idx = [_series indexOfObject:series];
		if(idx != NSNotFound) {
			FMSpatialProjection *proj = _projections[idx];
			_series = [_series arrayByRemovingObjectAtIndex:idx];
			_projections = [_projections arrayByRemovingObjectAtIndex:idx];
			
			if(![_projections containsObject:proj]) {
				NSMutableSet * newProjSet = [_projectionSet mutableCopy];
				[newProjSet removeObject:proj];
				_projectionSet = [newProjSet copy];
			}
            if([series conformsToProtocol:@protocol(FMDepthClient)]) {
                [self reconstructDepthClients];
            }
		}
	}
}

- (void)addPreRenderable:(id<FMAttachment>)object
{
	@synchronized(self) {
        NSArray <id<FMAttachment>> *old = _preRenderables;
		_preRenderables = [_preRenderables arrayByAddingObjectIfNotExists:object];
        if(old != _preRenderables && [object conformsToProtocol:@protocol(FMDepthClient)]) {
            [self reconstructDepthClients];
        }
	}
}

- (void)insertPreRenderable:(id<FMAttachment>)object atIndex:(NSUInteger)index
{
	@synchronized(self) {
		NSArray <id<FMAttachment>> *old = _preRenderables;
		_preRenderables = [_preRenderables arrayByInsertingObjectIfNotExists:object atIndex:index];
		if(old != _preRenderables && [object conformsToProtocol:@protocol(FMDepthClient)]) {
			[self reconstructDepthClients];
		}
	}
}

- (void)addPreRenderables:(NSArray<id<FMAttachment>> *)array
{
	@synchronized(self) {
		for(id<FMAttachment> pre in array) [self addPreRenderable:pre];
	}
}

- (void)removePreRenderable:(id<FMAttachment>)object
{
	@synchronized(self) {
        NSArray <id<FMAttachment>> *old = _preRenderables;
		_preRenderables = [_preRenderables arrayByRemovingObject:object];
        if(old != _preRenderables && [object conformsToProtocol:@protocol(FMDepthClient)]) {
            [self reconstructDepthClients];
        }
	}
}

- (void)addPostRenderable:(id<FMAttachment>)object
{
	@synchronized(self) {
        NSArray <id<FMAttachment>> *old = _postRenderables;
		_postRenderables = [_postRenderables arrayByAddingObjectIfNotExists:object];
        if(old != _postRenderables && [object conformsToProtocol:@protocol(FMDepthClient)]) {
            [self reconstructDepthClients];
        }
	}
}

- (void)addPostRenderables:(NSArray<id<FMAttachment>> *)array
{
	@synchronized(self) {
		for(id<FMAttachment> post in array) [self addPostRenderable:post];
	}
}

- (void)removePostRenderable:(id<FMAttachment>)object
{
	@synchronized(self) {
        NSArray <id<FMAttachment>> *old = _postRenderables;
		_postRenderables = [_postRenderables arrayByRemovingObject:object];
        if(old != _postRenderables && [object conformsToProtocol:@protocol(FMDepthClient)]) {
            [self reconstructDepthClients];
        }
	}
}

- (void)setClearDepth:(CGFloat)clearDepth
{
    if(_clearDepth != clearDepth) {
        @synchronized(self) {
            _clearDepth = clearDepth;
            [self reconstructDepthClients];
        }
    }
}

// このメソッドはprivateメソッドなので、synchronizedブロックを使っていない. 呼び出す側で管理する事.
- (void)reconstructDepthClients
{
    NSMutableArray<id> *objects = [NSMutableArray array];
    [objects addObjectsFromArray:_preRenderables];
    [objects addObjectsFromArray:_series];
    [objects addObjectsFromArray:_postRenderables];
    
    CGFloat currentBase = 0;
    CGFloat clearVal = 0;
    for(id obj in objects) {
        if([obj conformsToProtocol:@protocol(FMDepthClient)]) {
            CGFloat v = [(id<FMDepthClient>)obj requestDepthRangeFrom:currentBase objects:objects];
            currentBase += fabs(v);
            clearVal += fabs(MIN(0, v));
        }
    }
    _clearDepth = clearVal;
}

@end








