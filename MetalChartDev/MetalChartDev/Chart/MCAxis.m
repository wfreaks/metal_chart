//
//  MCAxis.m
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/11.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "MCAxis.h"
#import "Lines.h"
#import "Series.h"
#import "LineBuffers.h"

@interface MCAxis()

@property (readonly, nonatomic) MCDimensionalProjection *orthogonal;

@end



@interface MCBlockAxisConfigurator()

@property (copy, nonatomic) MCAxisConfiguratorBlock _Nonnull block;

@end




@implementation MCAxis

- (instancetype)initWithEngine:(Engine *)engine
					Projection:(MCSpatialProjection *)projection
					 dimension:(NSInteger)dimensionId
				 configuration:(id<MCAxisConfigurator>)conf
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
        [_axis.attributes setDimensionIndex:dimIndex];
		
		_orthogonal = projection.dimensions[(dimIndex == 0) ? 1 : 0];
		
		[self setupDefaultAttributes];
	}
	return self;
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
             chart:(MetalChart *)chart
              view:(MTKView *)view
{
	[_conf configureUniform:_axis.attributes withDimension:_dimension orthogonal:_orthogonal];
    [_axis encodeWith:encoder projection:_projection.projection];
	
    [_decoration encodeWith:encoder axis:self projection:_projection.projection];
}

- (void)setMinorTickCountPerMajor:(NSUInteger)count
{
    _axis.attributes.minorTicksPerMajor = (uint8_t)count;
}

- (void)setupDefaultAttributes
{
	UniformAxisAttributes *axis = _axis.attributes.axisAttributes;
	UniformAxisAttributes *major = _axis.attributes.majorTickAttributes;
	UniformAxisAttributes *minor = _axis.attributes.minorTickAttributes;
	
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


@implementation MCBlockAxisConfigurator

- (instancetype)initWithBlock:(MCAxisConfiguratorBlock)block
{
	self = [super init];
	if(self) {
		self.block = block;
	}
	return self;
}

- (void)configureUniform:(UniformAxisConfiguration *)uniform
		   withDimension:(MCDimensionalProjection *)dimension
			  orthogonal:(MCDimensionalProjection * _Nonnull)orthogonal
{
	_block(uniform, dimension, orthogonal);
}

@end


