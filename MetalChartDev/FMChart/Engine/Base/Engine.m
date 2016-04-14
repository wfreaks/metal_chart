//
//  LineEngine.m
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/03.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "Engine.h"
#import "DeviceResource.h"
#import "Buffers.h"
#import "MetalChart.h"

@interface FMEngine()

@property (strong, nonatomic) FMDeviceResource *resource;

@property (strong, nonatomic) id<MTLDepthStencilState> depthState_noDepth;
@property (strong, nonatomic) id<MTLDepthStencilState> depthState_depthAny;
@property (strong, nonatomic) id<MTLDepthStencilState> depthState_depthGreater;
@property (strong, nonatomic) id<MTLDepthStencilState> depthState_depthLess;

@end

@implementation FMEngine

- (instancetype)initWithResource:(FMDeviceResource *)resource
{
	self = [super init];
	if(self) {
		self.resource = [FMDeviceResource defaultResource];
        self.depthState_noDepth = [self.class depthStencilStateWithResource:resource writeDepth:NO depthFunc:MTLCompareFunctionAlways];
        self.depthState_depthAny = [self.class depthStencilStateWithResource:resource writeDepth:YES depthFunc:MTLCompareFunctionAlways];
        self.depthState_depthGreater = [self.class depthStencilStateWithResource:resource writeDepth:YES depthFunc:MTLCompareFunctionGreater];
        self.depthState_depthLess = [self.class depthStencilStateWithResource:resource writeDepth:YES depthFunc:MTLCompareFunctionLess];
	}
	return self;
}

- (id<MTLRenderPipelineState>)pipelineStateWithProjection:(FMUniformProjectionCartesian2D *)projection
												 vertFunc:(NSString *)vertFuncName
												 fragFunc:(NSString *)fragFuncName
											   writeDepth:(BOOL)writeDepth
{
	return [self pipelineStateWithFormat:projection.colorPixelFormat
							 sampleCount:projection.sampleCount
								vertFunc:vertFuncName
								fragFunc:fragFuncName
							  writeDepth:writeDepth];
}

- (id<MTLRenderPipelineState>)pipelineStateWithPolar:(FMUniformProjectionPolar *)projection
											vertFunc:(NSString *)vertFuncName
											fragFunc:(NSString *)fragFuncName
										  writeDepth:(BOOL)writeDepth
{
	return [self pipelineStateWithFormat:projection.colorPixelFormat
							 sampleCount:projection.sampleCount
								vertFunc:vertFuncName
								fragFunc:fragFuncName
							  writeDepth:writeDepth];
}

- (id<MTLRenderPipelineState>)pipelineStateWithFormat:(MTLPixelFormat)pixelFormat
										  sampleCount:(NSUInteger)sampleCount
											 vertFunc:(NSString *)vertFuncName
											 fragFunc:(NSString *)fragFuncName
										   writeDepth:(BOOL)writeDepth
{
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
		
        const MTLPixelFormat depthFormat = determineDepthPixelFormat();
        desc.depthAttachmentPixelFormat = depthFormat;
        desc.stencilAttachmentPixelFormat = (depthFormat == MTLPixelFormatDepth32Float_Stencil8) ? depthFormat : MTLPixelFormatInvalid;
        
		NSError *err = nil;
		state = [_resource.device newRenderPipelineStateWithDescriptor:desc error:&err];
        if(err) {
            NSLog(@"error : %@", err);
        }
		[_resource addRenderPipelineState:state];
	}
	return state;
}

+ (id<MTLDepthStencilState>)depthStencilStateWithResource:(FMDeviceResource *)resource
                                               writeDepth:(BOOL)writeDepth
                                                depthFunc:(MTLCompareFunction)func
{
	MTLDepthStencilDescriptor *desc = [[MTLDepthStencilDescriptor alloc] init];
    desc.depthCompareFunction = func;
	desc.depthWriteEnabled = writeDepth;
	
	return [resource.device newDepthStencilStateWithDescriptor:desc];
}

@end



