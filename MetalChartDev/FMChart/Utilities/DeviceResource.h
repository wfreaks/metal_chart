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

@interface FMDeviceResource : NSObject

@property (readonly, nonatomic) id<MTLDevice> _Nonnull device;
@property (readonly, nonatomic) id<MTLLibrary> _Nonnull library;
@property (readonly, nonatomic) NSDictionary *_Nonnull renderStates;
@property (readonly, nonatomic) NSDictionary * _Nonnull computeStates;
@property (readonly, nonatomic) NSDictionary * _Nonnull samplerStates;
@property (readonly, nonatomic) id<MTLCommandQueue> _Nonnull queue;

+ (instancetype _Nullable)defaultResource;

- (instancetype _Nullable)initWithDevice:(id<MTLDevice> _Nullable)device;

- (BOOL)addRenderPipelineState:(id<MTLRenderPipelineState> _Nonnull)state;

- (BOOL)addComputePipelineState:(id<MTLComputePipelineState> _Nonnull)state
						 forKey:(NSString * _Nonnull)key;

- (BOOL)addSamplerState:(id<MTLSamplerState> _Nonnull)state
				  forKey:(NSString * _Nonnull)key;

@end
