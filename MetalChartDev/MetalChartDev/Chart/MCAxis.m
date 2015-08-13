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
@property (assign, nonatomic) NSUInteger dimOrder;

@end

@interface MCTick()<MCRenderable>

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
		[_attributes setWidth:1];
		[_attributes setColorWithRed:0 green:0 blue:0 alpha:1.0];
		
		MCDimensionalProjection *dimension = [projection dimensionWithId:dimensionId];
		
		if(dimension == nil) {
			// これはプログラマがちゃんと注意してdimensionIdを作ってればこうはならないはず.
			// projection.dimensionsはreadonlyかつimmutableなので、基本的に不注意だとか動的に決めたりだとか
			// （その場合はallocの前にチェックするべき）さえなければ、あとは単純なコーディングミスのみになる.
			abort();
		}
		_dimOrder = [projection.dimensions indexOfObject:dimension];
	}
	return self;
}

- (void)willEncodeWith:(id<MTLRenderCommandEncoder>)encoder
				 chart:(MetalChart *)chart
				  view:(MTKView *)view
{
	[self configureWithChart:chart view:view];
	[self configureVertex];
	[_line encodeWith:encoder projection:_projectionBuffer];
	if(_tick) [_tick encodeWith:encoder projection:_projectionBuffer];
}

- (void)configureWithChart:(MetalChart *)chart
					  view:(MTKView *)view
{
	_projectionBuffer.sampleCount = view.sampleCount;
	_projectionBuffer.physicalSize = view.bounds.size;
	_projectionBuffer.colorPixelFormat = view.colorPixelFormat;
	_projectionBuffer.padding = chart.padding;
}

// 頂点位置とprojectionの設定.
// 基本的に頂点位置は固定とし、すべてprojectionのvalueScale/valueOffsetで吸収する.
// 軸方向は常にplotエリア全体に伸ばす.
// 方針としてはTickに渡すprojectionが大部分を吸収できるようにすること、である.
- (void)configureVertex
{
	vertex_buffer *ptr = [_series.vertices bufferAtIndex:0];
	const BOOL isHorizontal = (_dimOrder == 0);
	MCDimensionalProjection *orthDim = (isHorizontal ? _projection.dimensions[1] : _projection.dimensions[0]);
	const float orthScale = (_anchorToProjection) ? (orthDim.max - orthDim.min) / 2 : 1;
	const float valueOffset = _anchorPoint;
	if(isHorizontal) {
		[_projectionBuffer setValueScale:CGSizeMake(1, orthScale)];
		[_projectionBuffer setValueOffset:CGSizeMake(0, valueOffset)];
		ptr[0].position = vector2((float)-1, 0.0f);
		ptr[1].position = vector2((float)+1, 0.0f);
	} else {
		[_projectionBuffer setValueScale:CGSizeMake(orthScale, 1)];
		[_projectionBuffer setValueOffset:CGSizeMake(valueOffset, 0)];
		ptr[0].position = vector2(0.0f, (float)-1);
		ptr[1].position = vector2(0.0f, (float)+1);
	}
}

@end

@implementation MCTick

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
		projection:(UniformProjection *)projection
{
	
}

@end
