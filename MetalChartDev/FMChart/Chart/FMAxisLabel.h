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

/**
 * FMAxisLabelDelegate protocol defines methods which label content (string and attributes) provider should implements.
 * To draw multiple lines at once, you should provide separate instances of NSMutableAttributedString, instead of inserting a '\n' charactor.
 * Default fonts will be applied to returned NSMutableAttributedString instances if provided, so caching lines might cause problems.
 *
 * @param value a value (in an axis dimension) on which an associated tick will be placed.
 * @param index index of an associated tick (a tick with index 0 is placed on the least value of all ticks drawn on screen).
 * @param lastIndex index of a tick with the greatest value of all ticks drawn on screen.
 * @param dimension dimension which an axis is placed along.
 */
@protocol FMAxisLabelDelegate<NSObject>

- (NSArray<NSMutableAttributedString*> * _Nonnull)attributedStringForValue:(CGFloat)value
																	 index:(NSInteger)index
																	  last:(NSInteger)lastIndex
																 dimension:(FMDimensionalProjection * _Nonnull)dimension
;

@end


/**
 * FMLineDrawHook protocol allows you to perform CoreGraphics operation before drawing each text line.
 * This function is provided solely by FMAxisLabel implementation, and cannot be used by any other class.
 */

@protocol FMLineDrawHook<NSObject>

/**
 * @param string a line to be rendered
 * @param context
 * @param drawRect a bounding box to be used to render a line.
 */

- (void)willDrawString:(NSAttributedString * _Nonnull)string
			 toContext:(CGContextRef _Nonnull)context
			  drawRect:(const CGRect *_Nonnull)drawRect
;

@end


typedef void (^FMLineHookBlock)(NSAttributedString * _Nonnull string,
								CGContextRef _Nonnull context,
								const CGRect *_Nonnull drawRect);

/**
 * A blocks-wrapper class for FMLineDrawHook.
 */

@interface FMBlockLineDrawHook : NSObject<FMLineDrawHook>

@property (nonatomic, copy, readonly) FMLineHookBlock _Nonnull block;

- (instancetype _Nonnull)initWithBlock:(FMLineHookBlock _Nonnull)block
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init
UNAVAILABLE_ATTRIBUTE;

+ (instancetype _Nonnull)hookWithBlock:(FMLineHookBlock _Nonnull)block;

@end


/**
 * A callback interface to manipulate a drawing box of a line provied by FMAxisLabelDelegate.
 * This interface is used to manipulate behaviors of FMLineRenderer, which is not for casual users (developers).
 * Used in FMAxis (and its subclasses) implementations.
 */

typedef void (^FMLineConfBlock)(NSUInteger idx, CGSize lineSize, CGSize bufferSize, CGRect *_Nonnull drawRect);


/**
 * A class that manages CGBitmapContext and draw text to it using CoreText, then copes its content to MTLTexture.
 * It's not a class that you have to use, but you may do so if you know what it does (but i dont think you will need to).
 */

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

/**
 * Modifies a range of 'valid label cache' (to invalidate labels on screen in most cases) that a FMAxisLabel manages.
 * Behavior is undefined on incrementing oldMaxIdx / decrementing oldMinIdx.
 */

typedef void (^LabelCacheModifierBlock)(const NSInteger newMinIdx,
										const NSInteger newMaxIdx,
										NSInteger * _Nonnull oldMinIdx,
										NSInteger * _Nonnull oldMaxIdx);

/**
 * FMAxisLabel provides a way to display a label around each major tick of an axis on 2-dim cartesian space.
 * An instance of FMAxisLabel uses a FMLabelRenderer internally.
 *
 * You must provide at least axis and delegate to draw labels.
 * textAlignment/textOffset/lineSpace is params you should set for configuring text placement.
 *
 * You SHOULD NOT register a single FMAxisLabel to multiple chart instances, obviously, even if you use FMSharedAxis.
 */

@interface FMAxisLabel : NSObject<FMDependentAttachment>

@property (nonatomic) id<FMAxis> _Nullable axis;
@property (readonly, nonatomic, weak) id<FMAxisLabelDelegate> _Nullable delegate;

// textをフレーム内に配置する際、内容によっては余白(場合によっては負値)が生じる。
// この余白をどう配分するかを制御するプロパティ, (0, 0)で全て右と下へ配置、(0.5,0.5)で等分に配置する.

/**
 *
 */
@property (assign  , nonatomic) CGPoint textAlignment;

/**
 *
 */
@property (assign  , nonatomic) CGPoint textOffset;

/**
 *
 */
@property (assign  , nonatomic) CGFloat lineSpace;

@property (copy	, nonatomic) LabelCacheModifierBlock  _Nullable cacheModifier;

/**
 *
 */
- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
							  frameSize:(CGSize)frameSize
						 bufferCapacity:(NSUInteger)capacity
						  labelDelegate:(id<FMAxisLabelDelegate> _Nonnull)delegate
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

/**
 *
 */
- (void)setFont:(UIFont * _Nonnull)font;

/**
 *
 */
- (void)setFrameOffset:(CGPoint)offset;

/**
 *
 */
- (void)setFrameAnchorPoint:(CGPoint)point;

/**
 *
 */
- (void)clearCache;

/**
 *
 */
- (void)setClearColor:(int32_t)color;

/**
 *
 */
- (void)setLineDrawHook:(id<FMLineDrawHook> _Nullable)hook;

@end


/**
 * FMSharedAxisLabel provide sharable axis labels (and drawing buffers) to multiple chart instances.
 * A reason why an FMAxisLabel instance cannot be shared is that its quad mapping parameters (texture to data space) depends on orthogonal dimensions.
 * (FMUniformRegion instance for data space will vary in each data space)
 */

@interface FMSharedAxisLabel : FMAxisLabel

@end


/**
 * Block interface for FMAxisLabelDelegate, arguments are identical.
 */

typedef NSArray<NSMutableAttributedString*> *_Nonnull (^FMAxisLabelDelegateBlock)(CGFloat value,
																				  NSInteger index,
																				  NSInteger lastIndex,
																				  FMDimensionalProjection *_Nonnull dimension);

/**
 * FMAxisLabelBlockDelegate is a simple wrapper class to implement FMAxisLabelDelegate using blocks.
 */
@interface FMAxisLabelBlockDelegate : NSObject<FMAxisLabelDelegate>

- (instancetype _Nonnull)initWithBlock:(FMAxisLabelDelegateBlock _Nonnull)block
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;


@end

