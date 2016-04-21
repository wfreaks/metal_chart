//
//  Points.m
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/27.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "Points.h"
#import <Metal/Metal.h>
#import "Engine.h"
#import "Buffers.h"
#import "PointBuffers.h"
#import "Series.h"

@implementation FMOrderedPointPrimitive

- (instancetype)initWithEngine:(FMEngine *)engine
						series:(FMOrderedSeries *)series
					attributes:(FMUniformPointAttributes * _Nullable)attributes
{
	self = [super init];
	if(self) {
		_engine = engine;
		FMDeviceResource *res = engine.resource;
		_attributes = (attributes) ? attributes : [[FMUniformPointAttributes alloc] initWithResource:res];
		_series = series;
	}
	return self;
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
projection:(FMUniformProjectionCartesian2D *)projection
{
	id<FMSeries> const series = self.series;
	if(series) {
		id<MTLRenderPipelineState> renderState = [self renderPipelineStateWithProjection:projection];
		id<MTLDepthStencilState> depthState = _engine.depthState_noDepth;
		[encoder pushDebugGroup:@"DrawPoint"];
		[encoder setRenderPipelineState:renderState];
		[encoder setDepthStencilState:depthState];
		
		id<MTLBuffer> const vertexBuffer = [series vertexBuffer];
		id<MTLBuffer> const pointBuffer = _attributes.buffer;
		id<MTLBuffer> const projBuffer = projection.buffer;
		id<MTLBuffer> const infoBuffer = [series info].buffer;
		[encoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];
		[encoder setVertexBuffer:pointBuffer offset:0 atIndex:1];
		[encoder setVertexBuffer:projBuffer offset:0 atIndex:2];
		[encoder setVertexBuffer:infoBuffer offset:0 atIndex:3];
		
		[encoder setFragmentBuffer:pointBuffer offset:0 atIndex:0];
		[encoder setFragmentBuffer:projBuffer offset:0 atIndex:1];
		
		const NSUInteger offset = [self vertexOffsetWithOffset:[series info].offset];
		const NSUInteger count = [self vertexCountWithCount:[series info].count];
		[encoder drawPrimitives:MTLPrimitiveTypePoint vertexStart:offset vertexCount:count];
		
		[encoder popDebugGroup];
	}
}

- (id<MTLRenderPipelineState>)renderPipelineStateWithProjection:(FMUniformProjectionCartesian2D *)projection
{
	return [_engine pipelineStateWithProjection:projection vertFunc:[self vertexFunctionName] fragFunc:@"Point_Fragment" writeDepth:YES];
}

- (NSUInteger)vertexCountWithCount:(NSUInteger)count { return count; }

- (NSUInteger)vertexOffsetWithOffset:(NSUInteger)offset { return offset; }

- (NSString *)vertexFunctionName { return @"Point_VertexOrdered"; }

@end


@implementation FMOrderedAttributedPointPrimitive

- (instancetype)initWithEngine:(FMEngine *)engine
						series:(FMOrderedAttributedSeries * _Nullable)series
			attributesCapacity:(NSUInteger)capacity
{
	self = [super init];
	if(self) {
		_engine = engine;
		_attributesArray = [[FMUniformPointAttributesArray alloc] initWithResource:engine.resource capacity:capacity];
		_series = series;
	}
	return self;
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
		projection:(FMUniformProjectionCartesian2D *)projection
{
	id<FMSeries> const series = self.series;
	if(series) {
		id<MTLRenderPipelineState> renderState = [self renderPipelineStateWithProjection:projection];
		id<MTLDepthStencilState> depthState = _engine.depthState_noDepth;
		[encoder pushDebugGroup:@"DrawAttributedPoint"];
		[encoder setRenderPipelineState:renderState];
		[encoder setDepthStencilState:depthState];
		
		id<MTLBuffer> const vertexBuffer = [series vertexBuffer];
		id<MTLBuffer> const pointBuffer = _attributesArray.buffer;
		id<MTLBuffer> const projBuffer = projection.buffer;
		id<MTLBuffer> const infoBuffer = [series info].buffer;
		[encoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];
		[encoder setVertexBuffer:pointBuffer offset:0 atIndex:1];
		[encoder setVertexBuffer:projBuffer offset:0 atIndex:2];
		[encoder setVertexBuffer:infoBuffer offset:0 atIndex:3];
		
		[encoder setFragmentBuffer:pointBuffer offset:0 atIndex:0];
		[encoder setFragmentBuffer:projBuffer offset:0 atIndex:1];
		
		const NSUInteger offset = [self vertexOffsetWithOffset:[series info].offset];
		const NSUInteger count = [self vertexCountWithCount:[series info].count];
		[encoder drawPrimitives:MTLPrimitiveTypePoint vertexStart:offset vertexCount:count];
		
		[encoder popDebugGroup];
	}
}

- (id<MTLRenderPipelineState>)renderPipelineStateWithProjection:(FMUniformProjectionCartesian2D *)projection
{
	return [_engine pipelineStateWithProjection:projection vertFunc:[self vertexFunctionName] fragFunc:@"Point_Fragment" writeDepth:YES];
}

- (NSUInteger)vertexCountWithCount:(NSUInteger)count { return count; }

- (NSUInteger)vertexOffsetWithOffset:(NSUInteger)offset { return offset; }

- (NSString *)vertexFunctionName { return @"Point_VertexOrderedAttributed"; }

@end


