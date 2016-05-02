//
//  FMText.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/09/16.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Metal/MTLTypes.h>
#import "FMAxis.h"
#import "Prototypes.h"

@protocol MTLTexture;

@protocol FMAxisLabelDelegate<NSObject>

- (NSArray<NSMutableAttributedString*> * _Nonnull)attributedStringForValue:(CGFloat)value
																	 index:(NSInteger)index
																	  last:(NSInteger)lastIndex
																 dimension:(FMDimensionalProjection * _Nonnull)dimension
;

@end



typedef void (^FMLineConfBlock)(NSUInteger idx, CGSize lineSize, CGSize bufferSize, CGRect *_Nonnull drawRect);

@protocol FMLineDrawHook<NSObject>

- (void)willDrawString:(NSAttributedString * _Nonnull)string
			 toContext:(CGContextRef _Nonnull)context
			  drawRect:(const CGRect *_Nonnull)drawRect
;

@end



typedef void (^FMLineHookBlock)(NSAttributedString * _Nonnull string,
								CGContextRef _Nonnull context,
								const CGRect *_Nonnull drawRect);

@interface FMBlockLineDrawHook : NSObject<FMLineDrawHook>

@property (nonatomic, copy, readonly) FMLineHookBlock _Nonnull block;

- (instancetype _Nonnull)initWithBlock:(FMLineHookBlock _Nonnull)block
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init
UNAVAILABLE_ATTRIBUTE;

+ (instancetype _Nonnull)hookWithBlock:(FMLineHookBlock _Nonnull)block;

@end



// Class that manages CGBitmapContext and draw text to it, then copes its contents to MTLTexture.
// It's not a class that you have to use, but you may do so if you know what it does.

@interface FMLineRenderer : NSObject

@property (readonly, nonatomic) CGSize bufferPixelSize;
@property (readonly, nonatomic) CGSize bufferSize;
@property (strong  , nonatomic) UIFont * _Nullable font;
@property (nonatomic) int32_t		  clearColor; // 順序が0xAGBRである事に注意.
@property (nonatomic, weak)			id<FMLineDrawHook> _Nullable hook;

- (instancetype _Nonnull)initWithPixelWidth:(NSUInteger)width
									 height:(NSUInteger)height
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;


- (void)drawLines:(NSArray<NSMutableAttributedString*> * _Nonnull)lines
		toTexture:(id<MTLTexture> _Nonnull)texture
		   region:(MTLRegion)region
		confBlock:(FMLineConfBlock _Nonnull)block
;

@end

// ラベルの位置がずれて描画処理が走る際に、デフォルトではこれまで表示されてなかった場所のみ、つまり
// oldRangeになくてnewRangeに含まれるインデックスのみを書き換えるが、この挙動を変更するために
// このブロックを用いる. 何をしているのか、理解した上で用いる事.
typedef void (^LabelCacheModifierBlock)(const NSInteger newMinIdx,
										const NSInteger newMaxIdx,
										NSInteger * _Nonnull oldMinIdx,
										NSInteger * _Nonnull oldMaxIdx);


@interface FMAxisLabel : NSObject<FMDependentAttachment>

@property (readonly, nonatomic) FMTextureQuadPrimitive * _Nonnull quad;
@property (readonly, nonatomic, weak) id<FMAxisLabelDelegate> _Nullable delegate;
@property (assign  , nonatomic) CGFloat lineSpace;
@property (nonatomic) id<FMAxis> _Nullable axis;

// textをフレーム内に配置する際、内容によっては余白(場合によっては負値)が生じる。
// この余白をどう配分するかを制御するプロパティ, (0, 0)で全て右と下へ配置、(0.5,0.5)で等分に配置する.
@property (assign  , nonatomic) CGPoint textAlignment;
@property (assign  , nonatomic) CGPoint textOffset;

@property (copy	, nonatomic) LabelCacheModifierBlock  _Nullable cacheModifier;

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
							  frameSize:(CGSize)frameSize
						 bufferCapacity:(NSUInteger)capacity
						  labelDelegate:(id<FMAxisLabelDelegate> _Nonnull)delegate
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;


- (void)setFont:(UIFont * _Nonnull)font;
- (void)setFrameOffset:(CGPoint)offset;
- (void)setFrameAnchorPoint:(CGPoint)point;
- (void)clearCache;

// hacky methods, do not use them unless you REALLY need them.

- (void)setClearColor:(int32_t)color;
- (void)setLineDrawHook:(id<FMLineDrawHook> _Nullable)hook;

@end



@interface FMSharedAxisLabel : FMAxisLabel

@end



typedef NSArray<NSMutableAttributedString*> *_Nonnull (^FMAxisLabelDelegateBlock)(CGFloat value,
																				  NSInteger index,
																				  NSInteger lastIndex,
																				  FMDimensionalProjection *_Nonnull dimension);

@interface FMAxisLabelBlockDelegate : NSObject<FMAxisLabelDelegate>

- (instancetype _Nonnull)initWithBlock:(FMAxisLabelDelegateBlock _Nonnull)block
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;


@end

