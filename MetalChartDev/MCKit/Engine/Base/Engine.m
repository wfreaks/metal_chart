//
//  LineEngine.m
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/08/03.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "Engine.h"
#import "DeviceResource.h"
#import "Buffers.h"

@interface Engine()

@property (strong, nonatomic) DeviceResource *resource;

@property (strong, nonatomic) id<MTLDepthStencilState> depthState_writeDepth;
@property (strong, nonatomic) id<MTLDepthStencilState> depthState_noDepth;

@end

@implementation Engine

- (instancetype)initWithResource:(DeviceResource *)resource
{
	self = [super init];
	if(self) {
		self.resource = [DeviceResource defaultResource];
        self.depthState_writeDepth = [self.class depthStencilStateWithResource:resource writeDepth:YES];
        self.depthState_noDepth = [self.class depthStencilStateWithResource:resource writeDepth:NO];
	}
	return self;
}

- (id<MTLRenderPipelineState>)pipelineStateWithProjection:(UniformProjection *)projection
												 vertFunc:(NSString *)vertFuncName
												 fragFunc:(NSString *)fragFuncName
{
	const NSUInteger sampleCount = projection.sampleCount;
	const MTLPixelFormat pixelFormat = projection.colorPixelFormat;
	NSString *label = [NSString stringWithFormat:@"%@_%@(%lu,%d)", vertFuncName, fragFuncName, (unsigned long)sampleCount, (int)pixelFormat];
	id<MTLRenderPipelineState> state = _resource.renderStates[label];
	if(state == nil) {
		MTLRenderPipelineDescriptor *desc = [[MTLRenderPipelineDescriptor alloc] init];
		desc.label = label;
		desc.vertexFunction = [_resource.library newFunctionWithName:vertFuncName];
        desc.fragmentFunction = [_resource.library newFunctionWithName:fragFuncName];
		desc.sampleCount = sampleCount;
        MTLRenderPipelineColorAttachmentDescriptor *cd = desc.colorAttachments[0];
		cd.pixelFormat = pixelFormat;
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
		state = [_resource.device newRenderPipelineStateWithDescriptor:desc error:&err];
        if(err) {
            NSLog(@"error : %@", err);
        }
		[_resource addRenderPipelineState:state];
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

@end



