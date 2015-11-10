//
//  TextureQuads.h
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/09/16.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Protocols.h"

@class Engine;
@class UniformProjectionCartesian2D;
@class UniformRegion;

@protocol MTLRenderCommandEncoder;
@protocol MTLTexture;

@interface TextureQuad : NSObject

@property (readonly, nonatomic) Engine * _Nonnull engine;
@property (readonly, nonatomic) UniformRegion * _Nonnull dataRegion;
@property (readonly, nonatomic) UniformRegion * _Nonnull texRegion;
@property (strong  , nonatomic) id<MTLTexture> _Nullable texture;

- (instancetype _Nonnull)initWithEngine:(Engine * _Nonnull)engine
                                         texture:(id<MTLTexture> _Nullable)texture;
;

- (void)encodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
        projection:(UniformProjectionCartesian2D * _Nonnull)projection
             count:(NSUInteger)count;
;

@end
