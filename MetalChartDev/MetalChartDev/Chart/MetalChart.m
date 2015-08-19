//
//  MetalChart.m
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/09.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "MetalChart.h"
#import "Buffers.h"

@interface NSArray (Utility)

- (_Nonnull instancetype)arrayByAddingObjectIfNotExists:(id _Nonnull)object;
- (_Nonnull instancetype)arrayByRemovingObject:(id _Nonnull)object;
- (_Nonnull instancetype)arrayByRemovingObjectAtIndex:(NSUInteger)index;

@end

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

@property (strong, nonatomic) NSArray<id<MCPreRenderable>> *preRenderables;
@property (strong, nonatomic) NSArray<id<MCPostRenderable>> *postRenderables;

@property (strong, nonatomic) dispatch_semaphore_t semaphore;

- (void)handlePanning:(UIPanGestureRecognizer * _Nonnull)recognizer;
- (void)handlePinching:(UIPinchGestureRecognizer * _Nonnull)recognizer;

@end

@implementation NSArray (Utility)

- (instancetype)arrayByAddingObjectIfNotExists:(id)object
{
	return ([self containsObject:object]) ? self : [self arrayByAddingObject:object];
}

- (instancetype)arrayByRemovingObject:(id)object
{
	if([self containsObject:object]) {
		NSMutableArray *ar = [self mutableCopy];
		[ar removeObject:object];
		return [ar copy];
	}
	return self;
}

- (instancetype)arrayByRemovingObjectAtIndex:(NSUInteger)index
{
	if(self.count > index) {
		NSMutableArray *ar = [self mutableCopy];
		[ar removeObjectAtIndex:index];
		return [ar copy];
	}
	return self;
}

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
		_semaphore = dispatch_semaphore_create(2);
	}
	return self;
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
	// 描画前にバッファへ書き込むのでここは無視する.
}

// かなり長く見えるが、同期を短くしたり分岐を分岐を整理するためだけの行が多い. 大雑把に言って、
// semaphore_wait 前は 各配列を破綻しないようキャプチャ / projectionの更新
// semaphore_wait 内では preRenderable / series / postRenderable 
// semaphore_signale 後は レンダリングバッファをプッシュしてコミット
// という流れになる.
- (void)drawInMTKView:(MTKView *)view
{
	
	void (^willDraw)(MetalChart * _Nonnull) = _willDraw;
	if(willDraw != nil) willDraw(self);
	
	NSArray<id<MCRenderable>> *seriesArray = nil;
	NSArray<MCSpatialProjection *> *projectionArray = nil;
	NSArray<id<MCPreRenderable>> *preRenderables = nil;
	NSArray<id<MCPostRenderable>> *postRenderables = nil;
	
	@synchronized(self) {
		seriesArray = _series;
		projectionArray = _projections;
		preRenderables = _preRenderables;
		postRenderables = _postRenderables;
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
			id<MTLRenderCommandEncoder> encoder = [buffer renderCommandEncoderWithDescriptor:pass];
			
			for(id<MCPreRenderable> renderable in preRenderables) {
				[renderable willEncodeWith:encoder chart:self view:view];
			}
			
			const NSUInteger count = seriesArray.count;
			for(NSUInteger i = 0; i < count; ++i) {
				id<MCRenderable> series = seriesArray[i];
				MCSpatialProjection *projection = projectionArray[i];
				[series encodeWith:encoder projection:projection.projection];
			}
			
			for(id<MCPostRenderable> renderable in postRenderables) {
				[renderable didEncodeWith:encoder chart:self view:view];
			}
			
			[encoder endEncoding];
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
		}
	}
}

// immutableなcollectionを使ってるので非常にまどろっこしいが、描画サイクルの度に防御的コピーを強制されるならこちらの方がよほど
// パフォーマンス的にはまともだと思われたため.
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
		}
	}
}

- (void)addPreRenderable:(id<MCPreRenderable>)object
{
	@synchronized(self) {
		_preRenderables = [_preRenderables arrayByAddingObjectIfNotExists:object];
	}
}

- (void)removePreRenderable:(id<MCPreRenderable>)object
{
	@synchronized(self) {
		_preRenderables = [_preRenderables arrayByRemovingObject:object];
	}
}

- (void)addPostRenderable:(id<MCPostRenderable>)object
{
	@synchronized(self) {
		_postRenderables = [_postRenderables arrayByAddingObjectIfNotExists:object];
	}
}

- (void)removePostRenderable:(id<MCPostRenderable>)object
{
	@synchronized(self) {
		_postRenderables = [_postRenderables arrayByRemovingObject:object];
	}
}

- (void)addToPanRecognizer:(UIPanGestureRecognizer *)recognizer
{
	[recognizer addTarget:self action:@selector(handlePanning:)];
}

- (void)removeFromPanRecognizer:(UIPanGestureRecognizer *)recognizer
{
	[recognizer removeTarget:self action:@selector(handlePanning:)];
}

- (void)handlePanning:(UIPanGestureRecognizer *)recognizer
{
	
}

- (void)addToPinchRecognizer:(UIPinchGestureRecognizer *)recognizer
{
	[recognizer addTarget:self action:@selector(handlePinching:)];
}

- (void)removeFromPinchRecognizer:(UIPinchGestureRecognizer *)recognizer
{
	[recognizer removeTarget:self action:@selector(handlePinching:)];
}

- (void)handlePinching:(UIPinchGestureRecognizer *)recognizer
{
	
}

@end








