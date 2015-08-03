//
//  DeviceResource.h
//  mmd_dev
//
//  Created by Keisuke Mori on 2014/08/22.
//  Copyright (c) 2014年 wfreaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/MTLDevice.h>
#import <Metal/MTLLibrary.h>
#import <Metal/MTLRenderPipeline.h>
#import <Metal/MTLSampler.h>

@interface DeviceResource : NSObject

@property (readonly, nonatomic) id<MTLDevice> device;
@property (readonly, nonatomic) id<MTLLibrary> library;
@property (readonly, nonatomic) NSDictionary *renderStates;
@property (readonly, nonatomic) NSDictionary *computeStates;
@property (readonly, nonatomic) NSDictionary *samplerStates;
@property (readonly, nonatomic) id<MTLCommandQueue> queue;

+ (DeviceResource *)defaultResource;

- (BOOL)addRenderPipelineState:(id<MTLRenderPipelineState>)state;

- (BOOL)addComputePipelineState:(id<MTLComputePipelineState>)state
						 forKey:(NSString *)key;

- (BOOL)addSamplerState:(id<MTLSamplerState>)state
				  forKey:(NSString *)key;

@end
