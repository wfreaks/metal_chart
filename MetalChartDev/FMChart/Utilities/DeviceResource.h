//
//  DeviceResource.h
//  FMChart
//
//  Created by Keisuke Mori on 2014/08/22.
//  Copyright (c) 2014年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/MTLDevice.h>
#import <Metal/MTLLibrary.h>
#import <Metal/MTLRenderPipeline.h>
#import <Metal/MTLSampler.h>

/**
 * Represents devices and resources that should be reused.
 * (command queue and pipeline state objects).
 */

@interface FMDeviceResource : NSObject

@property (readonly, nonatomic) id<MTLDevice> _Nonnull device;
@property (readonly, nonatomic) NSDictionary <NSString*, id<MTLRenderPipelineState>> *_Nonnull renderStates;
@property (readonly, nonatomic) NSDictionary <NSString*, id<MTLComputePipelineState>> * _Nonnull computeStates;
@property (readonly, nonatomic) NSDictionary <NSString*, id<MTLSamplerState>> * _Nonnull samplerStates;
@property (readonly, nonatomic) id<MTLCommandQueue> _Nonnull queue;

/**
 * create resource objects using [MTLDevice defaultDevice].
 */
+ (instancetype _Nullable)defaultResource;

/**
 * Create and initialize resources with a given metal device.
 * If device given is null, then [MTLDevice defaultDevice] will be used.
 */
- (instancetype _Nullable)initWithDevice:(id<MTLDevice> _Nullable)device;

/**
 * add a MTLRenderPipelineState object into cache using a state.label as a key.
 */

- (BOOL)addRenderPipelineState:(id<MTLRenderPipelineState> _Nonnull)state;

/**
 * add a MTLComputePipelineState object into cache using a state.label as a key.
 */
- (BOOL)addComputePipelineState:(id<MTLComputePipelineState> _Nonnull)state
						 forKey:(NSString * _Nonnull)key;

/**
 * add a MTLRenderPipelineState object into cache using a state.
 */
- (BOOL)addSamplerState:(id<MTLSamplerState> _Nonnull)state
				  forKey:(NSString * _Nonnull)key;

@end
