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

@implementation PlotRect

- (instancetype)initWithEngine:(Engine *)engine
{
    self = [super init];
    if(self) {
        _engine = engine;
        DeviceResource *res = engine.resource;
        _rect = [[UniformPlotRect alloc] initWithResource:res];
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
    
    id<MTLBuffer> const rectBuffer = _rect.buffer;
    id<MTLBuffer> const projBuffer = projection.buffer;
    [encoder setVertexBuffer:rectBuffer offset:0 atIndex:0];
    [encoder setVertexBuffer:projBuffer offset:0 atIndex:1];
    [encoder setFragmentBuffer:rectBuffer offset:0 atIndex:0];
    [encoder setFragmentBuffer:projBuffer offset:0 atIndex:1];
    
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    
    [encoder popDebugGroup];
}

@end
