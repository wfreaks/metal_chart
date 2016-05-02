//
//  DeviceResource.m
//  FMChart
//
//  Created by Keisuke Mori on 2014/08/22.
//  Copyright (c) 2014年 freaks. All rights reserved.
//

#import "DeviceResource.h"

@implementation FMDeviceResource
{
	NSMutableDictionary *_renderStates;
	NSMutableDictionary *_computeStates;
	NSMutableDictionary *_samplerStates;
}

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
	self = [super init];
	if( self ) {
		_device = (device) ? device : MTLCreateSystemDefaultDevice();
		_renderStates = [NSMutableDictionary dictionary];
		_computeStates = [NSMutableDictionary dictionary];
		_samplerStates = [NSMutableDictionary dictionary];
		_queue = [_device newCommandQueue];
	}
	return self;
}

- (BOOL)addRenderPipelineState:(id<MTLRenderPipelineState>)state
{
	NSString *label = state.label;
	if( label.length > 0 && _renderStates[label] == nil ) {
		_renderStates[label] = state;
		return YES;
	}
	return NO;
}

- (BOOL)addComputePipelineState:(id<MTLComputePipelineState>)state
						 forKey:(NSString *)key
{
	if( key.length > 0 && _computeStates[key] == nil ) {
		_computeStates[key] = state;
		return YES;
	}
	return NO;
}

- (BOOL)addSamplerState:(id<MTLSamplerState>)state
				 forKey:(NSString *)key
{
	if( key.length > 0 && _samplerStates[key] == nil ) {
		_samplerStates[key] = state;
		return YES;
	}
	return NO;
}

+ (instancetype _Nullable)defaultResource
{
	static FMDeviceResource* res = nil;
	if( res == nil ) {
		res = [[FMDeviceResource alloc] initWithDevice:nil];
	}
	return res;
}

@end
