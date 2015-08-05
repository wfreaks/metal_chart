//
//  LineEngine.m
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/08/03.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "LineEngine.h"
#import <Metal/Metal.h>
#import "LineEngine_common.h"
#import <UIKit/UIKit.h>

@interface LineEngine()

@property (strong, nonatomic) DeviceResource *resource;

@property (strong, nonatomic) id<MTLDepthStencilState> depthState_writeDepth;
@property (strong, nonatomic) id<MTLDepthStencilState> depthState_noDepth;

@end



@interface IndexedLine()

@property (strong, nonatomic) VertexBuffer *vertices;
@property (strong, nonatomic) IndexBuffer *indices;
@property (strong, nonatomic) UniformSeriesInfo *info;

@end



@implementation LineEngine

- (id)initWithResource:(DeviceResource *)resource
{
	self = [super init];
	if(self) {
		self.resource = [DeviceResource defaultResource];
        self.depthState_writeDepth = [self.class depthStencilStateWithResource:resource writeDepth:YES];
        self.depthState_noDepth = [self.class depthStencilStateWithResource:resource writeDepth:NO];
	}
	return self;
}

+ (id<MTLRenderPipelineState>)pipelineStateWithResource:(DeviceResource *)resource
											sampleCount:(NSUInteger)count
											pixelFormat:(MTLPixelFormat)format
                                             writeDepth:(BOOL)writeDepth
{
	NSString *label = [NSString stringWithFormat:@"LineEngineIndexed_%lu", (unsigned long)count];
	id<MTLRenderPipelineState> state = resource.renderStates[label];
	if(state == nil) {
		MTLRenderPipelineDescriptor *desc = [[MTLRenderPipelineDescriptor alloc] init];
		desc.label = label;
		desc.vertexFunction = [resource.library newFunctionWithName:@"LineEngineVertexIndexed"];
        desc.fragmentFunction = [resource.library newFunctionWithName:[NSString stringWithFormat:@"LineEngineFragment_%@", (writeDepth ? @"WriteDepth" : @"NoDepth")]];
		desc.sampleCount = count;
        MTLRenderPipelineColorAttachmentDescriptor *cd = desc.colorAttachments[0];
		cd.pixelFormat = format;
        cd.blendingEnabled = YES;
        cd.rgbBlendOperation = MTLBlendOperationAdd;
        cd.alphaBlendOperation = MTLBlendOperationAdd;
        cd.sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
        cd.sourceAlphaBlendFactor = MTLBlendFactorOne;
        cd.destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
        cd.destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
        
        desc.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
        desc.stencilAttachmentPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
        
		NSError *err = nil;
		state = [resource.device newRenderPipelineStateWithDescriptor:desc error:&err];
        if(err) {
            NSLog(@"error : %@", err);
        }
		[resource addRenderPipelineState:state];
	}
	return state;
}

+ (id<MTLDepthStencilState>)depthStencilStateWithResource:(DeviceResource *)resource
                                               writeDepth:(BOOL)writeDepth
{
	MTLDepthStencilDescriptor *desc = [[MTLDepthStencilDescriptor alloc] init];
    desc.depthCompareFunction = (writeDepth) ? MTLCompareFunctionGreater : MTLCompareFunctionAlways;
	desc.depthWriteEnabled = writeDepth;
	
	return [resource.device newDepthStencilStateWithDescriptor:desc];
}

- (void)encodeTo:(id<MTLCommandBuffer>)command
            pass:(MTLRenderPassDescriptor *)pass
          vertex:(VertexBuffer *)vertex
           index:(IndexBuffer *)index
      projection:(UniformProjection *)projection
      attributes:(UniformLineAttributes *)attributes
      seriesInfo:(UniformSeriesInfo *)info
{
    const NSUInteger sampleCount = projection.sampleCount;
    const MTLPixelFormat colorFormat = projection.colorPixelFormat;
    const BOOL writeDepth = ! attributes.enableOverlay;
    id<MTLRenderPipelineState> renderState = [self.class pipelineStateWithResource:_resource sampleCount:sampleCount pixelFormat:colorFormat writeDepth:writeDepth];
    id<MTLDepthStencilState> depthState = (writeDepth ? _depthState_writeDepth : _depthState_noDepth);
    id<MTLRenderCommandEncoder> encoder = [command renderCommandEncoderWithDescriptor:pass];
    [encoder setLabel:@"DrawLineEncoder"];
    [encoder pushDebugGroup:@"DrawLine"];
    [encoder setRenderPipelineState:renderState];
    [encoder setDepthStencilState:depthState];
    
    [encoder setVertexBuffer:vertex.buffer offset:0 atIndex:0];
    [encoder setVertexBuffer:index.buffer offset:0 atIndex:1];
    [encoder setVertexBuffer:projection.buffer offset:0 atIndex:2];
    [encoder setVertexBuffer:attributes.buffer offset:0 atIndex:3];
    [encoder setVertexBuffer:info.buffer offset:0 atIndex:4];
    
    [encoder setFragmentBuffer:projection.buffer offset:0 atIndex:0];
    [encoder setFragmentBuffer:attributes.buffer offset:0 atIndex:1];
    
    const NSUInteger count = 6 * (info.count - 1);
    if(count > 0) {
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:info.offset vertexCount:count instanceCount:1];
    }
    [encoder endEncoding];
}

- (void)encodeTo:(id<MTLCommandBuffer>)command
            pass:(MTLRenderPassDescriptor *)pass
     indexedLine:(IndexedLine *)line
      projection:(UniformProjection *)projection
{
    [self encodeTo:command
              pass:pass
            vertex:line.vertices
             index:line.indices
        projection:projection
        attributes:line.attributes
        seriesInfo:line.info];
}

@end


@implementation IndexedLine

- (id)initWithResource:(DeviceResource *)resource
        VertexCapacity:(NSUInteger)vertCapacity
         indexCapacity:(NSUInteger)idxCapacity
{
    self = [super init];
    if(self) {
        _vertices = [[VertexBuffer alloc] initWithResource:resource capacity:vertCapacity];
        _indices = [[IndexBuffer alloc] initWithResource:resource capacity:idxCapacity];
        _info = [[UniformSeriesInfo alloc] initWithResource:resource];
        _attributes = [[UniformLineAttributes alloc] initWithResource:resource];
        
        [_info info]->vertex_capacity = vertCapacity;
        [_info info]->index_capacity = idxCapacity;
    }
    return self;
}

- (void)setSampleData
{
    const NSUInteger vCount = _vertices.capacity;
    const NSUInteger iCount = _indices.capacity;
    for(int i = 0; i < vCount; ++i) {
        vertex_buffer *v = [_vertices bufferAtIndex:i];
        const float range = 0.5;
        v->position.x = ((2 * ((i  ) % 2)) - 1) * range;
        v->position.y = ((2 * ((i/2) % 2)) - 1) * range;
    }
    for(int i = 0; i < iCount; ++i) {
        index_buffer *idx = [_indices bufferAtIndex:i];
        idx->index = i % vCount;
    }
    _info.offset = 0;
    _info.count = iCount;
    
    [_attributes setColorWithRed:1 green:1 blue:0 alpha:0.5];
    [_attributes setWidth:3];
    [_attributes setModifyAlphaOnEdge:NO];
    _attributes.enableOverlay = NO;
}

@end




