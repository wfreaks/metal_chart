//
//  MCText.h
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/09/16.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Metal/MTLTypes.h>

@protocol MTLTexture;

@class DeviceResource;

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
