//
//  MCText.h
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/09/16.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Metal/MTLTypes.h>
#import "MCAxis.h"

@protocol MTLTexture;

@class DeviceResource;
@class Engine;
@class TextureQuad;

@interface MCTextBuffer : NSObject

@property (assign, nonatomic) CGSize size;
@property (strong, nonatomic) UIFont * _Nullable font;

- (instancetype _Null_unspecified)initWithBufferSize:(CGSize)size
;

- (void)drawString:(NSAttributedString * _Nonnull)string
         toTexture:(id<MTLTexture> _Nonnull)texture
       regionBlock:(MTLRegion(^ _Nonnull)(CGRect))block;
;

@end

@interface MCText : NSObject<MCAxisDecoration>

@property (readonly, nonatomic) MCTextBuffer * _Nonnull buffer;
@property (readonly, nonatomic) TextureQuad * _Nonnull quad;
@property (readonly, nonatomic) Engine * _Nonnull engine;

- (instancetype _Null_unspecified)initWithEngine:(Engine * _Nonnull)engine
                                     textureSize:(CGSize)size
;

@end

@protocol MCAxisLabelDelegate<NSObject>

- (NSAttributedString * _Nonnull)attributedStringForValue:(CGFloat)value
                                                dimension:(MCDimensionalProjection * _Nonnull)dimension
;

@end

