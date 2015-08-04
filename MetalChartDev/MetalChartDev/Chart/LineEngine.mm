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
		
		self.renderState = [self.class pipelineStateWithResource:resource];
	}
	return self;
}

+ (id<MTLRenderPipelineState>)pipelineStateWithResource:(DeviceResource *)resource
{
	NSString *label = @"RenderState_LineEngine";
	id<MTLRenderPipelineState> state = resource.renderStates[label];
	if(state == nil) {
		MTLRenderPipelineDescriptor *desc = [[MTLRenderPipelineDescriptor alloc] init];
		desc.label = label;
		desc.vertexFunction = [resource.library newFunctionWithName:@"LineEngineVertexIndexed"];
		desc.fragmentFunction = [resource.library newFunctionWithName:@"LineEngineFragment"];
		desc.colorAttachments[0].pixelFormat = MTLPixelFormatRGBA8Unorm;
		
		NSError *err = nil;
		state = [resource.device newRenderPipelineStateWithDescriptor:desc error:&err];
		[resource addRenderPipelineState:state];
	}
	return state;
}

- (void)encodeTo:(id<MTLCommandBuffer>)command
	  depthState:(id<MTLDepthStencilState>)depthState
			pass:(MTLRenderPassDescriptor *)pass
{
	
}

@end
