//
//  FMAxis.m
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/11.
//  Copyright © 2015 Keisuke Mori. All rights reserved.
//

#import "FMAxis.h"
#import "Lines.h"
#import "Series.h"
#import "LineBuffers.h"

@interface FMExclusiveAxis()

@property (readonly, nonatomic) FMDimensionalProjection *orthogonal;

@end



@interface FMBlockAxisConfigurator()

@property (copy, nonatomic) FMAxisConfiguratorBlock _Nonnull block;
@property (readonly, nonatomic) BOOL isFirst;

@end




@implementation FMExclusiveAxis

- (instancetype)initWithEngine:(FMEngine *)engine
					Projection:(FMProjectionCartesian2D *)projection
					 dimension:(NSInteger)dimensionId
				 configuration:(id<FMAxisConfigurator>)conf
{
	self = [super init];
	if(self) {
		_projection = projection;
		_axis = [[FMAxisPrimitive alloc] initWithEngine:engine];
		_conf = conf;
		_dimension = [projection dimensionWithId:dimensionId];
		
		if(_dimension == nil) {
			abort();
		}
		
		const NSUInteger dimIndex = [projection.dimensions indexOfObject:_dimension];
		[_axis.configuration setDimensionIndex:dimIndex];
		
		_orthogonal = projection.dimensions[(dimIndex == 0) ? 1 : 0];
		
		[FMExclusiveAxis setupDefaultAttributes:_axis];
	}
	return self;
}

- (FMProjectionCartesian2D *)projectionForChart:(FMMetalChart *)chart
{
	return _projection;
}

- (void)prepare:(FMMetalChart *)chart view:(FMMetalView *)view
{
	[_conf configureUniform:_axis.configuration withDimension:_dimension orthogonal:_orthogonal];
	const CGFloat len = _dimension.max - _dimension.min;
	// floorだと境界の挙動が怪しい. %.8fで見てもlen, intervalともに変化ないのに、countが変動する.
//	const NSUInteger majorTickCount = floor(len/_axis.configuration.majorTickInterval) + 1;
	const NSUInteger majorTickCount = round(len/_axis.configuration.majorTickInterval) + 1;
	_axis.configuration.maxMajorTicks = majorTickCount;
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
			 chart:(FMMetalChart *)chart
			  view:(FMMetalView *)view
{
	[_axis encodeWith:encoder projection:_projection.projection];
}

- (void)setMinorTickCountPerMajor:(NSUInteger)count
{
	_axis.configuration.minorTicksPerMajor = (uint8_t)count;
}

+ (void)setupDefaultAttributes:(FMAxisPrimitive *)primitive
{
	FMUniformAxisAttributes *axis = primitive.axisAttributes;
	FMUniformAxisAttributes *major = primitive.majorTickAttributes;
	FMUniformAxisAttributes *minor = primitive.minorTickAttributes;
	
	const float v = 0.4;
	[axis setColorRed:v green:v blue:v alpha:1.0];
	[axis setWidth:3];
	[axis setLineLength:1];
	
	[major setColorRed:v green:v blue:v alpha:0.8];
	[major setWidth:2];
	[major setLineLength:10];
	[major setLengthModifierStart:-1 end:0];
	
	[minor setColorRed:v green:v blue:v alpha:0.8];
	[minor setWidth:2];
	[minor setLineLength:8];
	[minor setLengthModifierStart:0 end:1];
}

@end

@interface FMSharedAxis()

@property (nonatomic, readonly) NSDictionary<NSString *, FMProjectionCartesian2D *> *projections;

@end

@implementation FMSharedAxis

- (instancetype)initWithEngine:(FMEngine *)engine
					 dimension:(FMDimensionalProjection *)dimension
				dimensionIndex:(NSUInteger)index
{
	self = [super init];
	if(self) {
		_axis = [[FMAxisPrimitive alloc] initWithEngine:engine];
		_dimension = dimension;
		_projections = @{};
		
		if(_dimension == nil) {
			abort();
		}
		
		[_axis.configuration setDimensionIndex:index];
		
		[FMExclusiveAxis setupDefaultAttributes:_axis];
		
		// いわゆるprepare:view:での設定を全てここで行ってしまう.
		[self configure:nil];
	}
	return self;
}

- (void)configure:(FMDimensionalProjection *)orthogonal
{
	const CGFloat len = _dimension.max - _dimension.min;
	const NSUInteger majorTickCount = round(len/_axis.configuration.majorTickInterval) + 1;
	_axis.configuration.maxMajorTicks = majorTickCount;
}

- (FMProjectionCartesian2D *)projectionForChart:(FMMetalChart *)chart
{
	FMProjectionCartesian2D *projection = _projections[chart.key];
#ifdef DEBUG
	NSAssert(projection != nil, @"no projection associated with chart for this FMSharedAxis, check you did call [axis setProjection:forChart:] beforehand.");
#endif
	return projection;
}

- (void)setMinorTickCountPerMajor:(NSUInteger)count
{
	[_axis.configuration setMinorTicksPerMajor:count];
}

- (void)prepare:(FMMetalChart *)chart view:(FMMetalView *)view
{
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
			 chart:(FMMetalChart *)chart
			  view:(FMMetalView *)view
{
	[_axis encodeWith:encoder projection:[self projectionForChart:chart].projection];
}

- (void)setProjection:(FMProjectionCartesian2D *)projection forChart:(FMMetalChart *)chart
{
	@synchronized(self) {
		NSMutableDictionary *dict = _projections.mutableCopy;
		dict[chart.key] = projection;
		_projections = dict.copy;
	}
}

- (void)removeProjectionForChart:(FMMetalChart *)chart
{
	@synchronized(self) {
		NSMutableDictionary *dict = _projections.mutableCopy;
		[dict removeObjectForKey:chart.key];
		_projections = dict.copy;
	}
}

@end

@implementation FMBlockAxisConfigurator

- (instancetype)initWithBlock:(FMAxisConfiguratorBlock)block
{
	self = [super init];
	if(self) {
		self.block = block;
		_isFirst = YES;
	}
	return self;
}

- (void)configureUniform:(FMUniformAxisConfiguration *)uniform
		   withDimension:(FMDimensionalProjection *)dimension
			  orthogonal:(FMDimensionalProjection *)orthogonal
{
	_block(uniform, dimension, orthogonal, _isFirst);
	_isFirst = NO;
}

+ (instancetype)configuratorWithFixedAxisAnchor:(CGFloat)axisAnchor
									 tickAnchor:(CGFloat)tickAnchor
								  fixedInterval:(CGFloat)tickInterval
								 minorTicksFreq:(uint8_t)minorPerMajor
{
	FMAxisConfiguratorBlock block = ^(FMUniformAxisConfiguration *conf,
									  FMDimensionalProjection *dim,
									  FMDimensionalProjection *orth,
									  BOOL isFirst) {
		const CGFloat v = MIN(orth.max, MAX(orth.min, axisAnchor));
		[conf setAxisAnchorDataValue:v];
		if(isFirst) {
			[conf setTickAnchorValue:tickAnchor];
			[conf setMajorTickInterval:tickInterval];
			[conf setMinorTicksPerMajor:minorPerMajor];
		}
	};
	return [[self alloc] initWithBlock:block];
}

+ (instancetype)configuratorWithRelativePosition:(CGFloat)axisPosition
									  tickAnchor:(CGFloat)tickAnchor
								   fixedInterval:(CGFloat)tickInterval
								  minorTicksFreq:(uint8_t)minorPerMajor
{
	FMAxisConfiguratorBlock block = ^(FMUniformAxisConfiguration *conf,
									  FMDimensionalProjection *dim,
									  FMDimensionalProjection *orth,
									  BOOL isFirst) {
		const CGFloat anchorNDC = (axisPosition * 2) - 1;
		[conf setAxisAnchorNDCValue:anchorNDC];
		if(isFirst) {
			[conf setTickAnchorValue:tickAnchor];
			[conf setMajorTickInterval:tickInterval];
			[conf setMinorTicksPerMajor:minorPerMajor];
		}
	};
	return [[self alloc] initWithBlock:block];
}

+ (instancetype)configuratorWithRelativePosition:(CGFloat)axisPosition
									  tickAnchor:(CGFloat)tickAnchor
								  minorTicksFreq:(uint8_t)minorPerMajor
									maxTickCount:(uint8_t)maxTick
							  intervalOfInterval:(CGFloat)interval
{
	FMAxisConfiguratorBlock block = ^(FMUniformAxisConfiguration *conf,
									  FMDimensionalProjection *dim,
									  FMDimensionalProjection *orth,
									  BOOL isFirst) {
		if(isFirst) {
			[conf setTickAnchorValue:tickAnchor];
			[conf setMinorTicksPerMajor:minorPerMajor];
			[conf setMaxMajorTicks:maxTick];
		}
		const CGFloat anchorNDC = (axisPosition * 2) - 1;
		[conf setAxisAnchorNDCValue:anchorNDC];
		const CGFloat vl = (dim.max - dim.min);
		const CGFloat minInterval = (vl / (maxTick-1));
		const CGFloat newInterval = interval * ceil(minInterval / interval);
		[conf setMajorTickInterval:newInterval];
	};
	return [[self alloc] initWithBlock:block];
}

@end


