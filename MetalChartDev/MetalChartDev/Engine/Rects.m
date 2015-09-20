//
//  Rects.m
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/26.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "Rects.h"
#import <Metal/Metal.h>
#import "Engine.h"
#import "Buffers.h"
#import "RectBuffers.h"
#import "Series.h"

@implementation PlotRect

- (instancetype)initWithEngine:(Engine *)engine
{
    self = [super init];
    if(self) {
        _engine = engine;
        DeviceResource *res = engine.resource;
        _attributes = [[UniformPlotRectAttributes alloc] initWithResource:res];
    }
    return self;
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder projection:(UniformProjection *)projection
{
    id<MTLRenderPipelineState> renderState = [_engine pipelineStateWithProjection:projection vertFunc:@"PlotRect_Vertex" fragFunc:@"PlotRect_Fragment"];
    id<MTLDepthStencilState> depthState = _engine.depthState_noDepth;
    [encoder pushDebugGroup:@"DrawPlotRect"];
    [encoder setRenderPipelineState:renderState];
    [encoder setDepthStencilState:depthState];
    
    const CGSize ps = projection.physicalSize;
    const RectPadding pr = projection.padding;
    const CGFloat scale = projection.screenScale;
    if(projection.enableScissor) {
        MTLScissorRect rect = {pr.left*scale, pr.top*scale, (ps.width-(pr.left+pr.right))*scale, (ps.height-(pr.bottom+pr.top))*scale};
        [encoder setScissorRect:rect];
    } else {
        MTLScissorRect rect = {0, 0, ps.width * scale, ps.height * scale};
        [encoder setScissorRect:rect];
    }
    
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

@interface BarPrimitive()

- (instancetype _Nonnull)initWithEngine:(Engine * _Nonnull)engine
									  attributes:(UniformBarAttributes * _Nullable)attributes
;

- (id<MTLRenderPipelineState> _Nonnull)renderPipelineStateWithProjection:(UniformProjection * _Nonnull)projection;
- (NSUInteger)vertexCountWithCount:(NSUInteger)count;
- (NSUInteger)vertexOffsetWithOffset:(NSUInteger)offset;
- (id<MTLBuffer> _Nullable)indexBuffer;
- (NSString * _Nonnull)vertexFunctionName;

@end

@implementation BarPrimitive

- (instancetype)initWithEngine:(Engine *)engine
					attributes:(UniformBarAttributes * _Nullable)attributes
{
    self = [super init];
    if(self) {
        _engine = engine;
        DeviceResource *res = engine.resource;
        _attributes = (attributes) ? attributes : [[UniformBarAttributes alloc] initWithResource:res];
    }
    return self;
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
        projection:(UniformProjection *)projection
{
	id<Series> const series = [self series];
	if(series) {
		id<MTLRenderPipelineState> renderState = [self renderPipelineStateWithProjection:projection];
		id<MTLDepthStencilState> depthState = _engine.depthState_noDepth;
		[encoder pushDebugGroup:@"DrawBar"];
		[encoder setRenderPipelineState:renderState];
		[encoder setDepthStencilState:depthState];
		
		const CGSize ps = projection.physicalSize;
		const RectPadding pr = projection.padding;
		const CGFloat scale = projection.screenScale;
		if(projection.enableScissor) {
			MTLScissorRect rect = {pr.left*scale, pr.top*scale, (ps.width-(pr.left+pr.right))*scale, (ps.height-(pr.bottom+pr.top))*scale};
			[encoder setScissorRect:rect];
		} else {
			MTLScissorRect rect = {0, 0, ps.width * scale, ps.height * scale};
			[encoder setScissorRect:rect];
		}
		
		id<MTLBuffer> const vertexBuffer = [series vertexBuffer];
		id<MTLBuffer> const indexBuffer = [self indexBuffer];
		id<MTLBuffer> const barBuffer = _attributes.buffer;
		id<MTLBuffer> const projBuffer = projection.buffer;
		id<MTLBuffer> const infoBuffer = [series info].buffer;
		[encoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];
		[encoder setVertexBuffer:indexBuffer offset:0 atIndex:1];
		[encoder setVertexBuffer:barBuffer offset:0 atIndex:2];
		[encoder setVertexBuffer:projBuffer offset:0 atIndex:3];
		[encoder setVertexBuffer:infoBuffer offset:0 atIndex:4];
		
		[encoder setFragmentBuffer:barBuffer offset:0 atIndex:0];
		[encoder setFragmentBuffer:projBuffer offset:0 atIndex:1];
		
		const NSUInteger offset = [self vertexOffsetWithOffset:[series info].offset];
		const NSUInteger count = [self vertexCountWithCount:[series info].count];
		[encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:offset vertexCount:count];
		
		[encoder popDebugGroup];
	}
}

- (id<MTLRenderPipelineState>)renderPipelineStateWithProjection:(UniformProjection *)projection
{
    return [_engine pipelineStateWithProjection:projection vertFunc:[self vertexFunctionName] fragFunc:@"GeneralBar_Fragment"];
}

- (NSUInteger)vertexCountWithCount:(NSUInteger)count { return 4 * count; }

- (NSUInteger)vertexOffsetWithOffset:(NSUInteger)offset { return 4 * offset; }

- (NSString *)vertexFunctionName { return @""; }

- (id<MTLBuffer>)indexBuffer { return nil; }

- (id<Series>)series { return nil; }

@end


@implementation OrderedBarPrimitive

- (instancetype)initWithEngine:(Engine *)engine
						series:(OrderedSeries *)series
					attributes:(UniformBarAttributes * _Nullable)attributes
{
    self = [super initWithEngine:engine attributes:attributes];
    if(self) {
        _series = series;
    }
    return self;
}

- (NSString *)vertexFunctionName { return @"GeneralBar_VertexOrdered"; }

@end






