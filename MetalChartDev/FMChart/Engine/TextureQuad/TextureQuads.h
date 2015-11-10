//
//  TextureQuads.h
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/09/16.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Protocols.h"

@class FMEngine;
@class FMUniformProjectionCartesian2D;
@class UniformRegion;

@protocol MTLRenderCommandEncoder;
@protocol MTLTexture;

@interface TextureQuad : NSObject

@property (readonly, nonatomic) FMEngine * _Nonnull engine;
@property (readonly, nonatomic) UniformRegion * _Nonnull dataRegion;
@property (readonly, nonatomic) UniformRegion * _Nonnull texRegion;
@property (strong  , nonatomic) id<MTLTexture> _Nullable texture;

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
                                         texture:(id<MTLTexture> _Nullable)texture;
;

- (void)encodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
        projection:(FMUniformProjectionCartesian2D * _Nonnull)projection
             count:(NSUInteger)count;
;

@end
