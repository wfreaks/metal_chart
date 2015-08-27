//
//  Points.m
//  MetalChartDev
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

@implementation PointPrimitive

- (instancetype)initWithEngine:(Engine *)engine series:(id<Series>)series
{
    self = [super init];
    if(self) {
        _engine = engine;
        _series = series;
        DeviceResource *res = engine.resource;
        _point = [[UniformPoint alloc] initWithResource:res];
    }
    return self;
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
projection:(UniformProjection *)projection
{
    id<MTLRenderPipelineState> renderState = [self renderPipelineStateWithProjection:projection];
    id<MTLDepthStencilState> depthState = _engine.depthState_noDepth;
    [encoder pushDebugGroup:@"DrawPoint"];
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
    
    id<MTLBuffer> const vertexBuffer = [_series vertexBuffer];
    id<MTLBuffer> const indexBuffer = [self indexBuffer];
    id<MTLBuffer> const pointBuffer = _point.buffer;
    id<MTLBuffer> const projBuffer = projection.buffer;
    id<MTLBuffer> const infoBuffer = [_series info].buffer;
    [encoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];
    [encoder setVertexBuffer:indexBuffer offset:0 atIndex:1];
    [encoder setVertexBuffer:pointBuffer offset:0 atIndex:2];
    [encoder setVertexBuffer:projBuffer offset:0 atIndex:3];
    [encoder setVertexBuffer:infoBuffer offset:0 atIndex:4];
    
    [encoder setFragmentBuffer:pointBuffer offset:0 atIndex:0];
    [encoder setFragmentBuffer:projBuffer offset:0 atIndex:1];
    
    const NSUInteger offset = [self vertexOffsetWithOffset:[_series info].offset];
    const NSUInteger count = [self vertexCountWithCount:[_series info].count];
    [encoder drawPrimitives:MTLPrimitiveTypePoint vertexStart:offset vertexCount:count];
    
    [encoder popDebugGroup];
}

- (id<MTLRenderPipelineState>)renderPipelineStateWithProjection:(UniformProjection *)projection
{
    return [_engine pipelineStateWithProjection:projection vertFunc:[self vertexFunctionName] fragFunc:@"Point_Fragment"];
}

- (NSUInteger)vertexCountWithCount:(NSUInteger)count { return count; }

- (NSUInteger)vertexOffsetWithOffset:(NSUInteger)offset { return offset; }

- (NSString *)vertexFunctionName { return @""; }

- (id<MTLBuffer>)indexBuffer { return nil; }

@end



@implementation OrderedPoint

- (instancetype)initWithEngine:(Engine *)engine series:(OrderedSeries *)series
{
    self = [super initWithEngine:engine series:series];
    if(self) {
        _orderedSeries = series;
    }
    return self;
}

- (NSString *)vertexFunctionName { return @"Point_VertexOrdered"; }

@end













