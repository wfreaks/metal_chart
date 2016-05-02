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


@interface FMSurfaceConfiguration : NSObject

@property (nonatomic, readonly) MTLPixelFormat colorPixelFormat;
@property (nonatomic, readonly) NSUInteger sampleCount;

- (instancetype _Nonnull)initWithFormat:(MTLPixelFormat)colorPixelFormat
							sampleCount:(NSUInteger)sampleCount
;

+ (instancetype _Nonnull)defaultConfiguration;

@end


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

- (id<MTLRenderPipelineState> _Nonnull)pipelineStateWithVertFunc:(id<MTLFunction> _Nonnull)vertFunc
														fragFunc:(id<MTLFunction> _Nonnull)fragFunc
													  writeDepth:(BOOL)writeDepth
;

// キャッシュされる, libraryがnilならdefautLibraryを使う. libraryは独自拡張とか使いたい時に指定する.
- (id<MTLFunction> _Nonnull)functionWithName:(NSString * _Nonnull)name
									 library:(id<MTLLibrary> _Nullable)library;

@end
