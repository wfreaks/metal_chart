//
//  FMText.h
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/09/16.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Metal/MTLTypes.h>
#import "FMAxis.h"

@protocol MTLTexture;

@class DeviceResource;
@class Engine;
@class TextureQuad;

@protocol FMAxisLabelDelegate<NSObject>

- (NSArray<NSMutableAttributedString*> * _Nonnull)attributedStringForValue:(CGFloat)value
													   dimension:(FMDimensionalProjection * _Nonnull)dimension
;

@end

typedef void (^FMLineConfBlock)(NSUInteger idx, CGSize lineSize, CGSize bufferSize, CGRect *_Nonnull drawRect);

// Class that manages CGBitmapContext and draw text to it, then copy its contents to MTLTexture.
// It's not a class that you have to use, but you may do so if you know what it does.

@interface FMLineRenderer : NSObject

@property (readonly, nonatomic) CGSize bufferPixelSize;
@property (readonly, nonatomic) CGSize  bufferSize;
@property (strong  , nonatomic) UIFont * _Nullable font;

- (instancetype _Nonnull)initWithPixelWidth:(NSUInteger)width
                                     height:(NSUInteger)height
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;


- (void)drawLine:(NSMutableAttributedString * _Nonnull)line
       toTexture:(id<MTLTexture> _Nonnull)texture
          region:(MTLRegion)region
       confBlock:(FMLineConfBlock _Nonnull)block
;

- (void)drawLines:(NSArray<NSMutableAttributedString*> * _Nonnull)lines
        toTexture:(id<MTLTexture> _Nonnull)texture
           region:(MTLRegion)region
        confBlock:(FMLineConfBlock _Nonnull)block
;

@end


// Label renderer for FMAxis.
// This class manages its own drawing buffer(MTLTexture to be precise), 
// and you should not use one instance from multiple Axis. 

@interface FMAxisLabel : NSObject<FMAxisDecoration>

@property (readonly, nonatomic) TextureQuad * _Nonnull quad;
@property (readonly, nonatomic) id<FMAxisLabelDelegate> _Nonnull delegate;
@property (assign  , nonatomic) CGFloat lineSpace;

// textをフレーム内に配置する際、内容によっては余白(場合によっては負値)が生じる。
// この余白をどう配分するかを制御するプロパティ, (0, 0)で全て右と下へ配置、(0.5,0.5)で等分に配置する.
@property (assign  , nonatomic) CGPoint textAlignment;

- (instancetype _Nonnull)initWithEngine:(Engine * _Nonnull)engine
							  frameSize:(CGSize)frameSize
						 bufferCapacity:(NSUInteger)capacity
						  labelDelegate:(id<FMAxisLabelDelegate> _Nonnull)delegate
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;


- (void)setFont:(UIFont * _Nonnull)font;
- (void)setFrameOffset:(CGPoint)offset;
- (void)setFrameAnchorPoint:(CGPoint)point;
- (void)clearCache;

@end

typedef NSArray<NSMutableAttributedString*> *_Nonnull (^FMAxisLabelDelegateBlock)(CGFloat value, FMDimensionalProjection *_Nonnull dimension);

@interface FMAxisLabelBlockDelegate : NSObject<FMAxisLabelDelegate>

- (instancetype _Nonnull)initWithBlock:(FMAxisLabelDelegateBlock _Nonnull)block
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;


@end

