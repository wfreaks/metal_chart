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

@interface FMPlotRectPrimitive()

@property (nonatomic, readonly) id<MTLRenderPipelineState> pipeline;

@end
@implementation FMPlotRectPrimitive

- (instancetype)initWithEngine:(FMEngine *)engine
{
	self = [super init];
	if(self) {
		_engine = engine;
		FMDeviceResource *res = engine.resource;
		_attributes = [[FMUniformPlotRectAttributes alloc] initWithResource:res];
		id<MTLFunction> vertFunc = [engine functionWithName:@"PlotRect_Vertex" library:nil];
		id<MTLFunction> fragFunc = [engine functionWithName:@"PlotRect_Fragment" library:nil];
		_pipeline = [engine pipelineStateWithVertFunc:vertFunc fragFunc:fragFunc writeDepth:YES];
	}
	return self;
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder projection:(FMUniformProjectionCartesian2D *)projection
{
	id<MTLRenderPipelineState> renderState = _pipeline;
	id<MTLDepthStencilState> depthState = _engine.depthState_depthLess;
	[encoder pushDebugGroup:NSStringFromClass(self.class)];
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

@property (nonatomic, readonly) id<MTLRenderPipelineState> pipeline;

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
						  configuration:(FMUniformBarConfiguration * _Nullable)conf
;

- (NSUInteger)vertexCountWithCount:(NSUInteger)count;
- (NSUInteger)vertexOffsetWithOffset:(NSUInteger)offset;
- (id<MTLBuffer> _Nullable)attributesBuffer;
+ (NSString * _Nonnull)vertexFunctionName;
+ (NSString * _Nonnull)fragmentFunctionName;

@end

@implementation FMBarPrimitive

- (instancetype)initWithEngine:(FMEngine *)engine
				 configuration:(FMUniformBarConfiguration * _Nullable)conf
{
	self = [super init];
	if(self) {
		_engine = engine;
		FMDeviceResource *res = engine.resource;
		_conf = (conf) ? conf : [[FMUniformBarConfiguration alloc] initWithResource:res];
		id<MTLFunction> vertFunc = [engine functionWithName:[self.class vertexFunctionName] library:nil];
		id<MTLFunction> fragFunc = [engine functionWithName:[self.class fragmentFunctionName] library:nil];
		_pipeline = [engine pipelineStateWithVertFunc:vertFunc fragFunc:fragFunc writeDepth:YES];
	}
	return self;
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
		projection:(FMUniformProjectionCartesian2D *)projection
{
	id<FMSeries> const series = [self series];
	if(series) {
		id<MTLRenderPipelineState> renderState = _pipeline;
		id<MTLDepthStencilState> depthState = _engine.depthState_depthGreater;
		[encoder pushDebugGroup:NSStringFromClass(self.class)];
		[encoder setRenderPipelineState:renderState];
		[encoder setDepthStencilState:depthState];
		
		id<MTLBuffer> const vertexBuffer = [series vertexBuffer];
		id<MTLBuffer> const barBuffer = _conf.buffer;
		id<MTLBuffer> const attrBuffer = [self attributesBuffer];
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

- (NSUInteger)vertexCountWithCount:(NSUInteger)count { return 6 * count; }

- (NSUInteger)vertexOffsetWithOffset:(NSUInteger)offset { return 6 * offset; }

+ (NSString *)vertexFunctionName { return nil; }
+ (NSString *)fragmentFunctionName { return @"GeneralBar_Fragment"; }

- (id<MTLBuffer>)attributesBuffer { return nil; }

- (id<FMSeries>)series { return nil; }

@end


@implementation FMOrderedBarPrimitive

- (instancetype)initWithEngine:(FMEngine *)engine
						series:(FMOrderedSeries *)series
				 configuration:(FMUniformBarConfiguration * _Nullable)conf
					attributes:(FMUniformBarAttributes * _Nullable)attr
{
	self = [super initWithEngine:engine configuration:conf];
	if(self) {
		_series = series;
		_attributes = (attr) ? attr : [[FMUniformBarAttributes alloc] initWithResource:engine.resource];
	}
	return self;
}

+ (NSString *)vertexFunctionName { return @"GeneralBar_VertexOrdered"; }

- (id<MTLBuffer>)attributesBuffer { return _attributes.buffer; }

@end





@implementation FMOrderedAttributedBarPrimitive

- (instancetype)initWithEngine:(FMEngine *)engine
						series:(FMOrderedAttributedSeries *)series
				 configuration:(FMUniformBarConfiguration * _Nullable)conf
			   attributesArray:(FMUniformBarAttributesArray * _Nullable)attrs
	attributesCapacityOnCreate:(NSUInteger)capacity
{
	self = [super initWithEngine:engine configuration:conf];
	if(self) {
		_series = series;
		_attributesArray = (attrs) ? attrs : [[FMUniformBarAttributesArray alloc] initWithResource:engine.resource capacity:capacity];
	}
	return self;
}

+ (NSString *)vertexFunctionName { return @"AttributedBar_VertexOrdered"; }
+ (NSString *)fragmentFunctionName { return @"AttributedBar_Fragment"; }

- (id<MTLBuffer>)attributesBuffer { return _attributesArray.buffer; }

@end



