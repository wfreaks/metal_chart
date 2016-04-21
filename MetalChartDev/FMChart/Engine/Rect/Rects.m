//
//  Rects.m
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/26.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "Rects.h"
#import <Metal/Metal.h>
#import "Engine.h"
#import "Buffers.h"
#import "RectBuffers.h"
#import "Series.h"

@implementation FMPlotRectPrimitive

- (instancetype)initWithEngine:(FMEngine *)engine
{
	self = [super init];
	if(self) {
		_engine = engine;
		FMDeviceResource *res = engine.resource;
		_attributes = [[FMUniformPlotRectAttributes alloc] initWithResource:res];
	}
	return self;
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder projection:(FMUniformProjectionCartesian2D *)projection
{
	id<MTLRenderPipelineState> renderState = [_engine pipelineStateWithProjection:projection vertFunc:@"PlotRect_Vertex" fragFunc:@"PlotRect_Fragment" writeDepth:YES];
	id<MTLDepthStencilState> depthState = _engine.depthState_depthLess;
	[encoder pushDebugGroup:@"DrawPlotRect"];
	[encoder setRenderPipelineState:renderState];
	[encoder setDepthStencilState:depthState];
	
	id<MTLBuffer> const rectBuffer = _attributes.buffer;
	id<MTLBuffer> const projBuffer = projection.buffer;
	[encoder setVertexBuffer:rectBuffer offset:0 atIndex:0];
	[encoder setVertexBuffer:projBuffer offset:0 atIndex:1];
	[encoder setFragmentBuffer:rectBuffer offset:0 atIndex:0];
	[encoder setFragmentBuffer:projBuffer offset:0 atIndex:1];
	
	[encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
	
	[encoder popDebugGroup];
}

@end

@interface FMBarPrimitive()

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
						  configuration:(FMUniformBarConfiguration * _Nullable)conf
							 attributes:(FMUniformBarAttributes * _Nullable)attr
;

- (id<MTLRenderPipelineState> _Nonnull)renderPipelineStateWithProjection:(FMUniformProjectionCartesian2D * _Nonnull)projection;
- (NSUInteger)vertexCountWithCount:(NSUInteger)count;
- (NSUInteger)vertexOffsetWithOffset:(NSUInteger)offset;
- (id<MTLBuffer> _Nullable)indexBuffer;
- (NSString * _Nonnull)vertexFunctionName;
- (NSString * _Nonnull)fragmentFunctionName;

@end

@implementation FMBarPrimitive

- (instancetype)initWithEngine:(FMEngine *)engine
				 configuration:(FMUniformBarConfiguration * _Nullable)conf
					attributes:(FMUniformBarAttributes * _Nullable)attr
{
	self = [super init];
	if(self) {
		_engine = engine;
		FMDeviceResource *res = engine.resource;
		_conf = (conf) ? conf : [[FMUniformBarConfiguration alloc] initWithResource:res];
		_attributes = (attr) ? attr : [[FMUniformBarAttributes alloc] initWithResource:res];
	}
	return self;
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
		projection:(FMUniformProjectionCartesian2D *)projection
{
	id<FMSeries> const series = [self series];
	if(series) {
		id<MTLRenderPipelineState> renderState = [self renderPipelineStateWithProjection:projection];
		id<MTLDepthStencilState> depthState = _engine.depthState_depthGreater;
		[encoder pushDebugGroup:@"DrawBar"];
		[encoder setRenderPipelineState:renderState];
		[encoder setDepthStencilState:depthState];
		
		id<MTLBuffer> const vertexBuffer = [series vertexBuffer];
		id<MTLBuffer> const barBuffer = _conf.buffer;
		id<MTLBuffer> const attrBuffer = _attributes.buffer;
		id<MTLBuffer> const projBuffer = projection.buffer;
		id<MTLBuffer> const infoBuffer = [series info].buffer;
		[encoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];
		[encoder setVertexBuffer:barBuffer offset:0 atIndex:1];
		[encoder setVertexBuffer:attrBuffer offset:0 atIndex:2];
		[encoder setVertexBuffer:projBuffer offset:0 atIndex:3];
		[encoder setVertexBuffer:infoBuffer offset:0 atIndex:4];
		
		[encoder setFragmentBuffer:barBuffer offset:0 atIndex:0];
		[encoder setFragmentBuffer:attrBuffer offset:0 atIndex:1];
		[encoder setFragmentBuffer:projBuffer offset:0 atIndex:2];
		
		const NSUInteger offset = [self vertexOffsetWithOffset:[series info].offset];
		const NSUInteger count = [self vertexCountWithCount:[series info].count];
		[encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:offset vertexCount:count];
		
		[encoder popDebugGroup];
	}
}

- (id<MTLRenderPipelineState>)renderPipelineStateWithProjection:(FMUniformProjectionCartesian2D *)projection
{
	return [_engine pipelineStateWithProjection:projection vertFunc:[self vertexFunctionName] fragFunc:[self fragmentFunctionName] writeDepth:YES];
}

- (NSUInteger)vertexCountWithCount:(NSUInteger)count { return 6 * count; }

- (NSUInteger)vertexOffsetWithOffset:(NSUInteger)offset { return 6 * offset; }

- (NSString *)vertexFunctionName { return @""; }
- (NSString *)fragmentFunctionName { return @"GeneralBar_Fragment"; }

- (id<MTLBuffer>)indexBuffer { return nil; }

- (id<FMSeries>)series { return nil; }

@end


@implementation FMOrderedBarPrimitive

- (instancetype)initWithEngine:(FMEngine *)engine
						series:(FMOrderedSeries *)series
				 configuration:(FMUniformBarConfiguration * _Nullable)conf
					attributes:(FMUniformBarAttributes * _Nullable)attr
{
	self = [super initWithEngine:engine configuration:conf attributes:attr];
	if(self) {
		_series = series;
	}
	return self;
}

- (NSString *)vertexFunctionName { return @"GeneralBar_VertexOrdered"; }

@end





@implementation FMOrderedAttributedBarPrimitive

- (instancetype)initWithEngine:(FMEngine *)engine
						series:(FMOrderedAttributedSeries *)series
				 configuration:(FMUniformBarConfiguration * _Nullable)conf
			  globalAttributes:(FMUniformBarAttributes * _Nullable)attr
			   attributesArray:(FMUniformRectAttributesArray * _Nullable)attrs attributesCapacityOnCreate:(NSUInteger)capacity
{
	self = [super initWithEngine:engine configuration:conf attributes:attr];
	if(self) {
		_series = series;
		_rectAttrs = (attrs) ? attrs : [[FMUniformRectAttributesArray alloc] initWithResource:engine.resource capacity:capacity];
	}
	return self;
}

- (NSString *)vertexFunctionName { return @"AttributedBar_VertexOrdered"; }
- (NSString *)fragmentFunctionName { return @"AttributedBar_Fragment"; }

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
		projection:(FMUniformProjectionCartesian2D *)projection
{
	id<FMSeries> const series = [self series];
	if(series) {
		id<MTLRenderPipelineState> renderState = [self renderPipelineStateWithProjection:projection];
		id<MTLDepthStencilState> depthState = self.engine.depthState_depthGreater;
		[encoder pushDebugGroup:@"DrawAttributedBar"];
		[encoder setRenderPipelineState:renderState];
		[encoder setDepthStencilState:depthState];
		
		id<MTLBuffer> const vertexBuffer = [series vertexBuffer];
		id<MTLBuffer> const barBuffer = self.conf.buffer;
		id<MTLBuffer> const attrBuffer = self.attributes.buffer;
		id<MTLBuffer> const attrsBuffer = self.rectAttrs.buffer;
		id<MTLBuffer> const projBuffer = projection.buffer;
		id<MTLBuffer> const infoBuffer = [series info].buffer;
		[encoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];
		[encoder setVertexBuffer:barBuffer offset:0 atIndex:1];
		[encoder setVertexBuffer:attrBuffer offset:0 atIndex:2];
		[encoder setVertexBuffer:projBuffer offset:0 atIndex:3];
		[encoder setVertexBuffer:infoBuffer offset:0 atIndex:4];
		
		[encoder setFragmentBuffer:barBuffer offset:0 atIndex:0];
		[encoder setFragmentBuffer:attrBuffer offset:0 atIndex:1];
		[encoder setFragmentBuffer:attrsBuffer offset:0 atIndex:2];
		[encoder setFragmentBuffer:projBuffer offset:0 atIndex:3];
		
		const NSUInteger offset = [self vertexOffsetWithOffset:[series info].offset];
		const NSUInteger count = [self vertexCountWithCount:[series info].count];
		[encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:offset vertexCount:count];
		
		[encoder popDebugGroup];
	}
}

@end



