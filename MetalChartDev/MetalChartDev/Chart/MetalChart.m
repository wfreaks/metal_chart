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

@interface MCDimensionalProjection()


@end


@interface MCSpatialProjection()

@property (strong, nonatomic) NSArray<MCDimensionalProjection *> * _Nonnull dimensions;
@property (strong, nonatomic) UniformProjection * _Nonnull projection;

@end


@interface MetalChart()

@property (strong, nonatomic) NSArray<id<MCRenderable>> *series;
@property (strong, nonatomic) NSArray<MCSpatialProjection *> *projections;
@property (strong, nonatomic) NSSet<MCSpatialProjection *> *projectionSet;

@property (strong, nonatomic) NSArray<id<MCAttachment>> *preRenderables;
@property (strong, nonatomic) NSArray<id<MCAttachment>> *postRenderables;

@property (strong, nonatomic) NSArray<id<MCDepthClient>> *depthClients;

@property (strong, nonatomic) dispatch_semaphore_t semaphore;

@end

@implementation MCDimensionalProjection

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

@end


@implementation MCSpatialProjection

- (instancetype)initWithDimensions:(NSArray<MCDimensionalProjection *> *)dimensions
{
	self = [super init];
	if(self) {
		_dimensions = [NSArray arrayWithArray:dimensions];
		_projection = [[UniformProjection alloc] initWithResource:[DeviceResource defaultResource]];
		_projection.enableScissor = YES;
	}
	return self;
}

- (NSUInteger)rank
{
	return _dimensions.count;
}

- (void)writeToBuffer
{
	MCDimensionalProjection *xDim = _dimensions[0];
	MCDimensionalProjection *yDim = _dimensions[1];
	[_projection setValueScale:CGSizeMake((xDim.max-xDim.min)/2, (yDim.max-yDim.min)/2)];
	[_projection setValueOffset:CGSizeMake(-(xDim.max+xDim.min)/2, -(yDim.max+yDim.min)/2)];
}

- (MCDimensionalProjection *)dimensionWithId:(NSInteger)dimensionId
{
	for(MCDimensionalProjection *p in _dimensions) {
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
        _depthClients = [NSArray array];
		_semaphore = dispatch_semaphore_create(2);
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
	void (^willDraw)(MetalChart * _Nonnull) = _willDraw;
	if(willDraw != nil) willDraw(self);
	
	NSArray<id<MCRenderable>> *seriesArray = nil;
	NSArray<MCSpatialProjection *> *projectionArray = nil;
	NSArray<id<MCAttachment>> *preRenderables = nil;
	NSArray<id<MCAttachment>> *postRenderables = nil;
    id<MCCommandBufferHook> hook = nil;
	
	@synchronized(self) {
		seriesArray = _series;
		projectionArray = _projections;
		preRenderables = _preRenderables;
		postRenderables = _postRenderables;
        hook = _bufferHook;
	}
	
	for(MCSpatialProjection *projection in _projectionSet) {
		[projection configure:view padding:_padding];
		[projection writeToBuffer];
	}
	
	id<MTLCommandBuffer> buffer = nil;
	id<MTLDrawable> drawable = nil;
	
	dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
	
	MTLRenderPassDescriptor *pass = view.currentRenderPassDescriptor;
	if(pass) {
		drawable = view.currentDrawable;
		if(drawable) {
			buffer = [[DeviceResource defaultResource].queue commandBuffer];
            
            [hook chart:self willStartEncodingToBuffer:buffer];
            
			id<MTLRenderCommandEncoder> encoder = [buffer renderCommandEncoderWithDescriptor:pass];
			
			for(id<MCAttachment> renderable in preRenderables) {
				[renderable encodeWith:encoder chart:self view:view];
			}
			
			const NSUInteger count = seriesArray.count;
			for(NSUInteger i = 0; i < count; ++i) {
				id<MCRenderable> series = seriesArray[i];
				MCSpatialProjection *projection = projectionArray[i];
				[series encodeWith:encoder projection:projection.projection];
			}
			
			for(id<MCAttachment> renderable in postRenderables) {
				[renderable encodeWith:encoder chart:self view:view];
			}
			
			[encoder endEncoding];
            
            [hook chart:self willCommitBuffer:buffer];
		}
	}
	
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
	
	void (^didDraw)(MetalChart * _Nonnull) = _didDraw;
	if(didDraw != nil) didDraw(self);
	
}

- (void)addSeries:(id<MCRenderable>)series projection:(MCSpatialProjection *)projection
{
	@synchronized(self) {
		if(![_series containsObject:series]) {
			_projectionSet = [_projectionSet setByAddingObject:projection];
			_projections = [_projections arrayByAddingObject:projection];
			_series = [_series arrayByAddingObject:series];
            if([series conformsToProtocol:@protocol(MCDepthClient)]) {
                [self reconstructDepthClients];
            }
		}
	}
}

- (void)addSeriesArray:(NSArray<id<MCRenderable>> *)series
		   projections:(NSArray<MCSpatialProjection *> *)projections
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
- (void)removeSeries:(id<MCRenderable>)series
{
	@synchronized(self) {
		const NSUInteger idx = [_series indexOfObject:series];
		if(idx != NSNotFound) {
			MCSpatialProjection *proj = _projections[idx];
			_series = [_series arrayByRemovingObjectAtIndex:idx];
			_projections = [_projections arrayByRemovingObjectAtIndex:idx];
			
			if(![_projections containsObject:proj]) {
				NSMutableSet * newProjSet = [_projectionSet mutableCopy];
				[newProjSet removeObject:proj];
				_projectionSet = [newProjSet copy];
			}
            if([series conformsToProtocol:@protocol(MCDepthClient)]) {
                [self reconstructDepthClients];
            }
		}
	}
}

- (void)addPreRenderable:(id<MCAttachment>)object
{
	@synchronized(self) {
        NSArray <id<MCAttachment>> *old = _preRenderables;
		_preRenderables = [_preRenderables arrayByAddingObjectIfNotExists:object];
        if(old != _preRenderables && [object conformsToProtocol:@protocol(MCDepthClient)]) {
            [self reconstructDepthClients];
        }
	}
}

- (void)addPreRenderables:(NSArray<id<MCAttachment>> *)array
{
	@synchronized(self) {
		for(id<MCAttachment> pre in array) [self addPreRenderable:pre];
	}
}

- (void)removePreRenderable:(id<MCAttachment>)object
{
	@synchronized(self) {
        NSArray <id<MCAttachment>> *old = _preRenderables;
		_preRenderables = [_preRenderables arrayByRemovingObject:object];
        if(old != _preRenderables && [object conformsToProtocol:@protocol(MCDepthClient)]) {
            [self reconstructDepthClients];
        }
	}
}

- (void)addPostRenderable:(id<MCAttachment>)object
{
	@synchronized(self) {
        NSArray <id<MCAttachment>> *old = _postRenderables;
		_postRenderables = [_postRenderables arrayByAddingObjectIfNotExists:object];
        if(old != _postRenderables && [object conformsToProtocol:@protocol(MCDepthClient)]) {
            [self reconstructDepthClients];
        }
	}
}

- (void)addPostRenderables:(NSArray<id<MCAttachment>> *)array
{
	@synchronized(self) {
		for(id<MCAttachment> post in array) [self addPostRenderable:post];
	}
}

- (void)removePostRenderable:(id<MCAttachment>)object
{
	@synchronized(self) {
        NSArray <id<MCAttachment>> *old = _postRenderables;
		_postRenderables = [_postRenderables arrayByRemovingObject:object];
        if(old != _postRenderables && [object conformsToProtocol:@protocol(MCDepthClient)]) {
            [self reconstructDepthClients];
        }
	}
}

// このメソッドはprivateメソッドなので、synchronizedブロックを使っていない. 呼び出す側で管理する事.
- (void)reconstructDepthClients
{
    // 複数のarrayから描画順にMCDepthClientを実装するオブジェクトを並べる必要があるので、
    // 単純なadd/removeでは管理できない。
    NSMutableArray<id<MCDepthClient>> *newClients = [NSMutableArray array];
    [self.class addDepthClientsIn:_preRenderables to:newClients];
    [self.class addDepthClientsIn:_series to:newClients];
    [self.class addDepthClientsIn:_postRenderables to:newClients];
    _depthClients = [newClients copy];
    
    CGFloat currentBase = 0.01; // 0だとclearValueと重なる可能性が高い.
    for(id<MCDepthClient> client in _depthClients) {
        currentBase += MAX(0, [client requestDepthRangeFrom:currentBase]);
    }
}

+ (void)addDepthClientsIn:(NSArray *)from to:(NSMutableArray<id<MCDepthClient>> *)to
{
    for(id object in from) {
        if([object conformsToProtocol:@protocol(MCDepthClient)]) {
            [to addObject:object];
        }
    }
}

@end








