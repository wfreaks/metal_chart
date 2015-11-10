//
//  FMAxis.m
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/11.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "FMAxis.h"
#import "Lines.h"
#import "Series.h"
#import "LineBuffers.h"

@interface FMAxis()

@property (readonly, nonatomic) FMDimensionalProjection *orthogonal;

@end



@interface FMBlockAxisConfigurator()

@property (copy, nonatomic) FMAxisConfiguratorBlock _Nonnull block;
@property (readonly, nonatomic) BOOL isFirst;

@end




@implementation FMAxis

- (instancetype)initWithEngine:(FMEngine *)engine
					Projection:(FMProjectionCartesian2D *)projection
					 dimension:(NSInteger)dimensionId
				 configuration:(id<FMAxisConfigurator>)conf
{
	self = [super init];
	if(self) {
		_projection = projection;
        _axis = [[Axis alloc] initWithEngine:engine];
		_conf = conf;
		_dimension = [projection dimensionWithId:dimensionId];
		
		if(_dimension == nil) {
			abort();
		}
        
		const NSUInteger dimIndex = [projection.dimensions indexOfObject:_dimension];
        [_axis.configuration setDimensionIndex:dimIndex];
		
		_orthogonal = projection.dimensions[(dimIndex == 0) ? 1 : 0];
		
		[self setupDefaultAttributes];
	}
	return self;
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
             chart:(MetalChart *)chart
              view:(MetalChart *)view
{
	[_conf configureUniform:_axis.configuration withDimension:_dimension orthogonal:_orthogonal];
    const CGFloat len = _dimension.max - _dimension.min;
    const NSUInteger majorTickCount = floor(len/_axis.configuration.majorTickInterval) + 1;
    [_axis encodeWith:encoder projection:_projection.projection maxMajorTicks:majorTickCount];
	
    [_decoration encodeWith:encoder axis:self projection:_projection.projection];
}

- (void)setMinorTickCountPerMajor:(NSUInteger)count
{
    _axis.configuration.minorTicksPerMajor = (uint8_t)count;
}

- (void)setupDefaultAttributes
{
	UniformAxisAttributes *axis = _axis.axisAttributes;
	UniformAxisAttributes *major = _axis.majorTickAttributes;
	UniformAxisAttributes *minor = _axis.minorTickAttributes;
	
    const float v = 0.4;
	[axis setColorWithRed:v green:v blue:v alpha:1.0];
	[axis setWidth:3];
	[axis setLineLength:1];
	
	[major setColorWithRed:v green:v blue:v alpha:0.8];
	[major setWidth:2];
	[major setLineLength:10];
	[major setLengthModifierStart:-1 end:0];
	
	[minor setColorWithRed:v green:v blue:v alpha:0.8];
	[minor setWidth:2];
	[minor setLineLength:8];
	[minor setLengthModifierStart:0 end:1];
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

- (void)configureUniform:(UniformAxisConfiguration *)uniform
		   withDimension:(FMDimensionalProjection *)dimension
			  orthogonal:(FMDimensionalProjection * _Nonnull)orthogonal
{
	_block(uniform, dimension, orthogonal, _isFirst);
    _isFirst = NO;
}

+ (instancetype)configuratorWithFixedAxisAnchor:(CGFloat)axisAnchor
                                     tickAnchor:(CGFloat)tickAnchor
                                  fixedInterval:(CGFloat)tickInterval
                                 minorTicksFreq:(uint8_t)minorPerMajor
{
    FMAxisConfiguratorBlock block = ^(UniformAxisConfiguration *conf,
                                      FMDimensionalProjection *dim,
                                      FMDimensionalProjection *orth,
                                      BOOL isFirst) {
		const CGFloat v = MIN(orth.max, MAX(orth.min, axisAnchor));
		[conf setAxisAnchorValue:v];
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
    FMAxisConfiguratorBlock block = ^(UniformAxisConfiguration *conf,
                                      FMDimensionalProjection *dim,
                                      FMDimensionalProjection *orth,
                                      BOOL isFirst) {
        const CGFloat min = orth.min;
        const CGFloat l = orth.max - min;
        const CGFloat anchor = min + (axisPosition * l);
        [conf setAxisAnchorValue:anchor];
        if(isFirst) {
            [conf setTickAnchorValue:tickAnchor];
            [conf setMajorTickInterval:tickInterval];
            [conf setMinorTicksPerMajor:minorPerMajor];
        }
    };
    return [[self alloc] initWithBlock:block];
}

@end


