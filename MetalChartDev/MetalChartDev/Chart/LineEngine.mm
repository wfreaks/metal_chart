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

@interface LineEngine()

@property (strong, nonatomic) DeviceResource *resource;
@property (assign, nonatomic) NSUInteger capacity;

@property (strong, nonatomic) id<MTLBuffer> vertexBuffer;
@property (strong, nonatomic) id<MTLBuffer> indexBuffer;
@property (strong, nonatomic) id<MTLBuffer> projectionBuffer;
@property (strong, nonatomic) id<MTLBuffer> attributesBuffer;
@property (strong, nonatomic) id<MTLBuffer> infoBuffer;

@property (strong, nonatomic) id<MTLRenderPipelineState> renderState;
@property (strong, nonatomic) id<MTLDepthStencilState> depthState;

@end

@implementation LineEngine

- (id)initWithResource:(DeviceResource *)resource
		bufferCapacity:(NSUInteger)capacity
{
	self = [super init];
	if(self) {
		self.resource = [DeviceResource defaultResource];
		self.capacity = capacity;
		self.vertexBuffer = [self.resource.device newBufferWithLength:sizeof(vertex_buffer)*capacity options:MTLResourceOptionCPUCacheModeWriteCombined];
		self.indexBuffer = [self.resource.device newBufferWithLength:sizeof(index_buffer)*capacity options:MTLResourceOptionCPUCacheModeWriteCombined];
		self.projectionBuffer = [self.resource.device newBufferWithLength:sizeof(uniform_projection) options:MTLResourceOptionCPUCacheModeWriteCombined];
		self.attributesBuffer = [self.resource.device newBufferWithLength:sizeof(uniform_line_attr) options:MTLResourceOptionCPUCacheModeWriteCombined];
        self.infoBuffer = [self.resource.device newBufferWithLength:sizeof(uniform_series_info_buffer) options:MTLResourceOptionCPUCacheModeWriteCombined];
		
		self.depthState = [self.class depthStencilStateWithResource:resource];
        
        index_buffer *indices = (index_buffer *)([self.indexBuffer contents]);
        vertex_buffer *vertices = (vertex_buffer *)([self.vertexBuffer contents]);
        for(int i = 0; i < _capacity; ++i) {
            indices[i].index = i;
            vertex_buffer& v = vertices[i];
            v.position.x = ((2 * ((i  ) % 2)) - 1.0) * 0.5;
            v.position.y = ((2 * ((i/2) % 2)) - 1.0) * 0.5;
        }
        uniform_line_attr* attr = (uniform_line_attr *)([self.attributesBuffer contents]);
        attr->color = vector4(1.0f, 1.0f, 0.0f, 1.0f);
        attr->width = 0.03;
        uniform_series_info_buffer* info = (uniform_series_info_buffer *)([self.infoBuffer contents]);
        info->capacity = self.capacity;
        info->offset = 0;
	}
	return self;
}

+ (id<MTLRenderPipelineState>)pipelineStateWithResource:(DeviceResource *)resource
											sampleCount:(NSUInteger)count
											pixelFormat:(MTLPixelFormat)format
{
	NSString *label = [NSString stringWithFormat:@"LineEngineIndexed_%lu", (unsigned long)count];
	id<MTLRenderPipelineState> state = resource.renderStates[label];
	if(state == nil) {
		MTLRenderPipelineDescriptor *desc = [[MTLRenderPipelineDescriptor alloc] init];
		desc.label = label;
		desc.vertexFunction = [resource.library newFunctionWithName:@"LineEngineVertexIndexed"];
		desc.fragmentFunction = [resource.library newFunctionWithName:@"LineEngineFragment"];
		desc.sampleCount = count;
        MTLRenderPipelineColorAttachmentDescriptor *cd = desc.colorAttachments[0];
		cd.pixelFormat = format;
        cd.blendingEnabled = YES;
        cd.rgbBlendOperation = MTLBlendOperationAdd;
        cd.alphaBlendOperation = MTLBlendOperationAdd;
        cd.sourceRGBBlendFactor = MTLBlendFactorOne;
        cd.sourceAlphaBlendFactor = MTLBlendFactorOne;
        cd.destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
        cd.destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
        
        desc.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;

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
{
	MTLDepthStencilDescriptor *desc = [[MTLDepthStencilDescriptor alloc] init];
	desc.depthCompareFunction = MTLCompareFunctionAlways;
	desc.depthWriteEnabled = YES;
	return [resource.device newDepthStencilStateWithDescriptor:desc];
}

- (void)encodeTo:(id<MTLCommandBuffer>)command
			pass:(MTLRenderPassDescriptor *)pass
	 sampleCount:(NSUInteger)count
		  format:(MTLPixelFormat)format
{
	id<MTLRenderPipelineState> renderState = [self.class pipelineStateWithResource:_resource sampleCount:count pixelFormat:format];
	id<MTLDepthStencilState> depthState = _depthState;
	id<MTLRenderCommandEncoder> encoder = [command renderCommandEncoderWithDescriptor:pass];
    [encoder setLabel:@"DrawLineEncoder"];
    [encoder pushDebugGroup:@"DrawLine"];
	[encoder setRenderPipelineState:renderState];
	[encoder setDepthStencilState:depthState];
    [encoder setCullMode:MTLCullModeNone];
	
	[encoder setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
	[encoder setVertexBuffer:_indexBuffer offset:0 atIndex:1];
	[encoder setVertexBuffer:_projectionBuffer offset:0 atIndex:2];
	[encoder setVertexBuffer:_attributesBuffer offset:0 atIndex:3];
    [encoder setVertexBuffer:_infoBuffer offset:0 atIndex:4];
	
	[encoder setFragmentBuffer:_attributesBuffer offset:0 atIndex:0];
	
    const NSUInteger vertexCount = 6 * (_capacity - 1);
	[encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:vertexCount instanceCount:1];
    
    [encoder popDebugGroup];
	
	[encoder endEncoding];
}

@end
