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

@property (strong, nonatomic) LineEngine *engine;
@property (strong, nonatomic) OrderedSeries *series;
@property (strong, nonatomic) OrderedPolyLine *line;
@property (strong, nonatomic) UniformProjection *projectionBuffer;

@property (assign, nonatomic) MetalChart *currentChart;
@property (assign, nonatomic) MTKView *currentView;
@property (assign, nonatomic) NSUInteger dimOrder;

@end

@implementation MCAxis

- (instancetype)initWithEngine:(LineEngine *)engine
					Projection:(MCSpatialProjection *)projection
					 dimension:(NSInteger)dimensionId
{
	self = [super init];
	if(self) {
		_engine = engine;
		_projection = projection;
		_dimensionId = dimensionId;
		
		DeviceResource *resource = engine.resource;
		_series = [[OrderedSeries alloc] initWithResource:resource vertexCapacity:2];
		_line = [[OrderedPolyLine alloc] initWithEngine:_engine orderedSeries:_series];
		_attributes = _line.attributes;
		_projectionBuffer = [[UniformProjection alloc] initWithResource:resource];
		
		_series.info.count = 2;
		[_attributes setWidth:3];
		[_attributes setColorWithRed:0 green:0 blue:0 alpha:1.0];
		
		MCDimensionalProjection *dimension = [projection dimensionWithId:dimensionId];
		if(dimension == nil) abort();							// これはプログラマがちゃんと注意してdimensionIdを作ってればこうはならないはずなのでabortする.
		_dimOrder = [projection.dimensions indexOfObject:dimension];
	}
	return self;
}

- (void)willEncodeTo:(id<MTLCommandBuffer>)buffer
		  renderPass:(MTLRenderPassDescriptor *)pass
			   chart:(MetalChart *)chart
				view:(MTKView *)view
{
	[self configureWithChart:chart view:view];
	[self configureVertex];
	[_line encodeTo:buffer renderPass:pass projection:_projectionBuffer];
}

- (void)configureWithChart:(MetalChart *)chart
					  view:(MTKView *)view
{
//	if(_currentChart != chart || _currentView != view) {
		_currentChart = chart;
		_currentView = view;
		_projectionBuffer.sampleCount = view.sampleCount;
		_projectionBuffer.physicalSize = view.bounds.size;
		_projectionBuffer.colorPixelFormat = view.colorPixelFormat;
		_projectionBuffer.padding = chart.padding;
//	}
}

- (void)configureVertex
{
	vertex_buffer *ptr = [_series.vertices bufferAtIndex:0];
	const BOOL isHorizontal = (_dimOrder == 0);
	MCDimensionalProjection *orthDim = (isHorizontal ? _projection.dimensions[1] : _projection.dimensions[0]);
	const float valueScale = (_anchorToProjection) ? (orthDim.max - orthDim.min) / 2 : 1;
	const float mid = (orthDim.min + orthDim.max) / 2;
	const float valueOffset = (_anchorToProjection) ? -mid : 0;
	if(isHorizontal) {
		[_projectionBuffer setValueScale:CGSizeMake(1, valueScale)];
		[_projectionBuffer setValueOffset:CGSizeMake(0, valueOffset)];
		ptr[0].position = vector2((float)-1, (float)_anchorPoint);
		ptr[1].position = vector2((float)+1, (float)_anchorPoint);
	} else {
		[_projectionBuffer setValueScale:CGSizeMake(valueScale, 1)];
		[_projectionBuffer setValueOffset:CGSizeMake(valueOffset, 0)];
		ptr[0].position = vector2((float)_anchorPoint, (float)-1);
		ptr[1].position = vector2((float)_anchorPoint, (float)+1);
	}
}

@end
