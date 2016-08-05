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
#import "FMMetalChart.h"


@implementation FMSurfaceConfiguration

- (instancetype)initWithFormat:(MTLPixelFormat)colorPixelFormat sampleCount:(NSUInteger)sampleCount
{
	self = [super init];
	if(self) {
		_colorPixelFormat = colorPixelFormat;
		_sampleCount = sampleCount;
	}
	return self;
}

+ (instancetype _Nonnull)defaultConfiguration
{
	return [[self alloc] initWithFormat:MTLPixelFormatBGRA8Unorm sampleCount:2];
}

@end




@interface FMEngine()

@property (nonatomic) FMDeviceResource *resource;

@property (nonatomic, readonly) NSMutableDictionary<NSString*, id<MTLFunction>> *functions;

@end

@implementation FMEngine

- (instancetype)initWithResource:(FMDeviceResource *)resource
						 surface:(FMSurfaceConfiguration *)surface
{
	self = [super init];
	if(self) {
		_resource = resource;
		_surface = surface;
		_depthState_noDepth = [self.class depthStencilStateWithResource:resource writeDepth:NO depthFunc:MTLCompareFunctionAlways];
		_depthState_depthAny = [self.class depthStencilStateWithResource:resource writeDepth:YES depthFunc:MTLCompareFunctionAlways];
		_depthState_depthGreater = [self.class depthStencilStateWithResource:resource writeDepth:YES depthFunc:MTLCompareFunctionGreater];
		_depthState_depthLess = [self.class depthStencilStateWithResource:resource writeDepth:YES depthFunc:MTLCompareFunctionLess];
		_functions = [NSMutableDictionary dictionary];
		
		id<MTLDevice> device = resource.device;
		NSBundle *bundle = [NSBundle bundleForClass:[FMEngine class]];
		NSString *path = [bundle pathForResource:@"default" ofType:@"metallib"];
		if(device && path) {
			NSError *error = nil;
			_defaultLibrary = [device newLibraryWithFile:path error:&error];
			if(error) {
				NSLog(@"error while loading metal lib file : %@", error);
			}
		} else {
			self = nil;
		}
	}
	return self;
}

+ (instancetype)createDefaultEngine
{
	return [[self alloc] initWithResource:[FMDeviceResource defaultResource] surface:[FMSurfaceConfiguration defaultConfiguration]];
}

- (id<MTLRenderPipelineState>)pipelineStateWithVertFunc:(id<MTLFunction>)vertFunc
											   fragFunc:(id<MTLFunction>)fragFunc
											 writeDepth:(BOOL)writeDepth
{
	NSString *label = [NSString stringWithFormat:@"%@_%@", [vertFunc name], [fragFunc name]];
	id<MTLRenderPipelineState> state = _resource.renderStates[label];
	if(state == nil) {
		MTLRenderPipelineDescriptor *desc = [[MTLRenderPipelineDescriptor alloc] init];
		desc.label = label;
		desc.vertexFunction = vertFunc;
		desc.fragmentFunction = fragFunc;
		desc.sampleCount = _surface.sampleCount;
		MTLRenderPipelineColorAttachmentDescriptor *cd = desc.colorAttachments[0];
		cd.pixelFormat = _surface.colorPixelFormat;
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

- (id<MTLFunction>)functionWithName:(NSString *)name library:(id<MTLLibrary>)library
{
	@synchronized(_functions) {
		id<MTLFunction> f = _functions[name];
		if(!f) {
			id<MTLLibrary> lib = (library) ? library : _defaultLibrary;
			f = [lib newFunctionWithName:name];
			_functions[name] = f;
		}
		return f;
	}
}

@end



