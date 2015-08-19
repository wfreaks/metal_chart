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

@interface MCBlockAxisConfigurator()

@property (copy, nonatomic) MCAxisConfiguratorBlock _Nonnull block;

@end

@implementation MCAxis

- (instancetype)initWithEngine:(LineEngine *)engine
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
        [_axis.uniform setDimensionIndex:dimIndex];
		
		[self setupDefaultAttributes];
	}
	return self;
}

- (void)willEncodeWith:(id<MTLRenderCommandEncoder>)encoder
				 chart:(MetalChart *)chart
				  view:(MTKView *)view
{
	[_conf configureUniform:_axis.uniform withDimension:_dimension];
    [_axis encodeWith:encoder projection:_projection.projection];
}

- (void)setMinorTickCountPerMajor:(NSUInteger)count
{
    _axis.uniform.minorTicksPerMajor = (uint8_t)count;
}

- (void)setupDefaultAttributes
{
	UniformAxisAttributes *axis = _axis.uniform.axisAttributes;
	UniformAxisAttributes *major = _axis.uniform.majorTickAttributes;
	UniformAxisAttributes *minor = _axis.uniform.minorTickAttributes;
	
	[axis setColorWithRed:0 green:0 blue:0 alpha:0.4];
	[axis setWidth:2];
	[axis setLineLength:80];
	
	[major setColorWithRed:0 green:0 blue:0 alpha:0.4];
	[major setWidth:1];
	[major setLineLength:5];
	
	[minor setColorWithRed:0 green:0 blue:0 alpha:0.4];
	[minor setWidth:1];
	[minor setLineLength:2];
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

- (void)configureUniform:(UniformAxis *)uniform withDimension:(MCDimensionalProjection *)dimension
{
	_block(uniform, dimension);
}

@end


