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
		
		self.depthState = [self.class depthStencilStateWithResource:resource];
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
		desc.colorAttachments[0].pixelFormat = MTLPixelFormatRGBA8Unorm;
		desc.sampleCount = count;
		desc.colorAttachments[0].pixelFormat = format;

		NSError *err = nil;
		state = [resource.device newRenderPipelineStateWithDescriptor:desc error:&err];
		[resource addRenderPipelineState:state];
	}
	return state;
}

+ (id<MTLDepthStencilState>)depthStencilStateWithResource:(DeviceResource *)resource
{
	MTLDepthStencilDescriptor *desc = [[MTLDepthStencilDescriptor alloc] init];
	desc.depthCompareFunction = MTLCompareFunctionGreater;
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
	[encoder setRenderPipelineState:renderState];
	[encoder setDepthStencilState:depthState];
	
	[encoder setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
	[encoder setVertexBuffer:_indexBuffer offset:0 atIndex:1];
	[encoder setVertexBuffer:_projectionBuffer offset:0 atIndex:2];
	[encoder setVertexBuffer:_attributesBuffer offset:0 atIndex:3];
	
	[encoder setFragmentBuffer:_attributesBuffer offset:0 atIndex:0];
	
	[encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_capacity];
	
	[encoder endEncoding];
}

@end
