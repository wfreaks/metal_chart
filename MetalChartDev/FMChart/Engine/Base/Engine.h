//
//  LineEngine.h
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/08/03.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

@class FMDeviceResource;
@class FMUniformProjectionCartesian2D;

@interface FMEngine : NSObject

@property (readonly, nonatomic) FMDeviceResource * _Nonnull resource;
@property (readonly, nonatomic) id<MTLDepthStencilState> _Nonnull depthState_noDepth;
@property (readonly, nonatomic) id<MTLDepthStencilState> _Nonnull depthState_depthAny;
@property (readonly, nonatomic) id<MTLDepthStencilState> _Nonnull depthState_depthGreater;
@property (readonly, nonatomic) id<MTLDepthStencilState> _Nonnull depthState_depthLess;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull) resource
;

- (id<MTLRenderPipelineState> _Nonnull)pipelineStateWithProjection:(FMUniformProjectionCartesian2D * _Nonnull)projection
                                                          vertFunc:(NSString * _Nonnull)vertFuncName
                                                          fragFunc:(NSString * _Nonnull)fragFuncName
                                                        writeDepth:(BOOL)writeDepth
;
											


@end
