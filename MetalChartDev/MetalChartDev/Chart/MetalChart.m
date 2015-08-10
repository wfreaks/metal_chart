//
//  MetalChart.m
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/09.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "MetalChart.h"
#import "Buffers.h"

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

@end


@implementation MCSpatialProjection

- (instancetype)initWithDimensions:(NSArray<MCDimensionalProjection *> *)dimensions
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
	MCDimensionalProjection *xDim = _dimensions[0];
	MCDimensionalProjection *yDim = _dimensions[1];
	[_projection setValueScale:CGSizeMake((xDim.max-xDim.min)/2, (yDim.max-yDim.min)/2)];
	[_projection setValueOffset:CGSizeMake(-(xDim.max+xDim.min)/2, -(yDim.max+yDim.min)/2)];
}

- (void)configure:(MTKView *)view
{
	[_projection setPhysicalSize:view.bounds.size];
	[_projection setSampleCount:view.sampleCount];
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
		_semaphore = dispatch_semaphore_create(2);
	}
	return self;
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
	// ここは無視する。描画前にバッファへ書き込むのでここは無視する.
}

- (void)drawInMTKView:(MTKView *)view
{
	NSArray<id<MCRenderable>> *seriesArray = nil;
	NSArray<MCSpatialProjection *> *projectionArray = nil;
	@synchronized(self) {
		seriesArray = _series;
		projectionArray = _projections;
		for(MCSpatialProjection *projection in _projectionSet) {
			[projection configure:view];
			[projection writeToBuffer];
		}
	}
	
	id<MTLCommandBuffer> buffer = nil;
	id<MTLDrawable> drawable = nil;
	
	dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
	
	MTLRenderPassDescriptor *pass = view.currentRenderPassDescriptor;
	if(pass) {
		drawable = view.currentDrawable;
		if(drawable) {
			buffer = [[DeviceResource defaultResource].queue commandBuffer];
			const NSUInteger count = seriesArray.count;
			for(NSUInteger i = 0; i < count; ++i) {
				id<MCRenderable> series = seriesArray[i];
				MCSpatialProjection *projection = projectionArray[i];
				[series renderWithCommandBuffer:buffer renderPass:pass projection:projection.projection];
			}
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
			NSMutableArray *newSeries = [_series mutableCopy];
			NSMutableArray *newProjections = [_projectionSet mutableCopy];
			
			[newSeries removeObjectAtIndex:idx];
			[newProjections removeObjectAtIndex:idx];
			
			_series = [newSeries copy];
			_projections = [newProjections copy];
			
			if(![_projections containsObject:proj]) {
				NSMutableSet * newProjSet = [_projectionSet mutableCopy];
				[newProjSet removeObject:proj];
				_projectionSet = [newProjSet copy];
			}
		}
	}
}

@end
