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

@interface MCAxis()

@end

@implementation MCAxis

- (instancetype)initWithEngine:(LineEngine *)engine
					Projection:(MCSpatialProjection *)projection
					 dimension:(NSInteger)dimensionId
{
	self = [super init];
	if(self) {
		_projection = projection;
		_dimensionId = dimensionId;
        _axis = [[Axis alloc] initWithEngine:engine];
		
//		DeviceResource *resource = engine.resource;
//		[_attributes setWidth:2];
//		[_attributes setColorWithRed:0.4 green:0.4 blue:0.4 alpha:0.4];
		
		MCDimensionalProjection *dimension = [projection dimensionWithId:dimensionId];
		
		if(dimension == nil) {
			abort();
		}
        
		const NSUInteger dimIndex = [projection.dimensions indexOfObject:dimension];
        [_axis.uniform setDimensionIndex:dimIndex];
	}
	return self;
}

- (void)willEncodeWith:(id<MTLRenderCommandEncoder>)encoder
				 chart:(MetalChart *)chart
				  view:(MTKView *)view
{
    [_axis encodeWith:encoder projection:_projection.projection];
}

- (void)setMinorTickCountPerMajor:(NSUInteger)count
{
    _axis.uniform.minorTicksPerMajor = (uint8_t)count;
}

@end

