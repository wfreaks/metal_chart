//
//  LineEngine.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/03.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "Prototypes.h"


/**
 * FMSurfaceConfiguration class defines immutable object that contains metal surface information
 * which can be used when configuring metal view and creating MTLRenderPipelineDescription instances.
 */

@interface FMSurfaceConfiguration : NSObject

@property (nonatomic, readonly) MTLPixelFormat colorPixelFormat;
@property (nonatomic, readonly) NSUInteger sampleCount;

- (instancetype _Nonnull)initWithFormat:(MTLPixelFormat)colorPixelFormat
							sampleCount:(NSUInteger)sampleCount
;

+ (instancetype _Nonnull)defaultConfiguration;

@end

/**
 * FMEngine is a core utility class that provides surface info, resource caches, and an easy way to create pipeline state objects.
 */

@interface FMEngine : NSObject

@property (nonatomic, readonly) FMDeviceResource * _Nonnull resource;
@property (nonatomic, readonly) FMSurfaceConfiguration * _Nonnull surface;
@property (nonatomic, readonly) id<MTLLibrary> _Nonnull defaultLibrary;
@property (nonatomic, readonly) id<MTLDepthStencilState> _Nonnull depthState_noDepth;
@property (nonatomic, readonly) id<MTLDepthStencilState> _Nonnull depthState_depthAny;
@property (nonatomic, readonly) id<MTLDepthStencilState> _Nonnull depthState_depthGreater;
@property (nonatomic, readonly) id<MTLDepthStencilState> _Nonnull depthState_depthLess;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull) resource
								  surface:(FMSurfaceConfiguration * _Nonnull)surface
;

+ (instancetype _Nonnull)createDefaultEngine;

/**
 * search pipeline state object , create one if not cached, then return it.
 */
- (id<MTLRenderPipelineState> _Nonnull)pipelineStateWithVertFunc:(id<MTLFunction> _Nonnull)vertFunc
														fragFunc:(id<MTLFunction> _Nonnull)fragFunc
													  writeDepth:(BOOL)writeDepth
;

/**
 * search function object from cache, create one using given library object (defaultLibrary will be used if nil), then return it.
 * you can provide a library object to use your custom shaders.
 */
- (id<MTLFunction> _Nonnull)functionWithName:(NSString * _Nonnull)name
									 library:(id<MTLLibrary> _Nullable)library;

@end
