//
//  FMRangeFilters.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/10.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMMetalChart.h"
#import "Prototypes.h"

/**
 * FMRangeFilter protocol defines components of FMProjectionUpdater.
 * An FMProjectionUpdater insatnce collects input values to determine min/max and provides them to filters,
 * and each filter modifies given values to fullfill your requirments.
 *
 * You can provide your own implementation and do whatever you want, but avoid using current values of FMDimensionalProjection
 * (doing so makes an feedback loop and may result in weird behavior ... )
 * I strongly recommend you to avoid making filters that depends on mutable states/values.
 */

NS_ASSUME_NONNULL_BEGIN

@protocol FMRangeFilter<NSObject>

- (void)updater:(FMProjectionUpdater * _Nonnull)updater
	   minValue:(CGFloat * _Nonnull)min
	   maxValue:(CGFloat * _Nonnull)max
;

@end


typedef void (^FilterBlock)(FMProjectionUpdater *_Nonnull updater, CGFloat * _Nonnull min, CGFloat * _Nonnull max);

/**
 * A simple block wrapper class for FMRangeFilter.
 */

@interface FMBlockFilter : NSObject<FMRangeFilter>

- (instancetype _Nonnull)initWithBlock:(FilterBlock _Nonnull)block
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

@end




/**
 * A filter that does not modify values but records them.
 */
@interface FMDefaultFilter : NSObject<FMRangeFilter>

@property (readonly, nonatomic) CGFloat currentMin;
@property (readonly, nonatomic) CGFloat currentMax;
@property (readonly, nonatomic) CGFloat currentLength;
@property (readonly, nonatomic) CGFloat currentCenter;

- (instancetype _Nonnull)init;

@end

// 範囲長を固定する. Anchorの値は-1でmin, +1でmaxを指し、その点を固定した状態で拡大縮小する.
// つまりanchor=-1の場合、minを変更せずmaxのみを動かし、anchor=0ならば中央値を固定してmin,maxを動かす.
// offsetはlengthによらない移動を提供する.
/**
 * A filter that fixes a length (in data space) using anchor and offset.
 * Anchor with value -1 is at min value, and +1 at max.
 * This filter satisfies 'newAnchoredValue = oldAnchoredValue + offset' and 'newMax - newMin = length'.
 */
@interface FMLengthFilter : NSObject<FMRangeFilter>

@property (readonly, nonatomic) CGFloat length;
@property (readonly, nonatomic) CGFloat anchor;
@property (readonly, nonatomic) CGFloat offset;

- (instancetype _Nonnull)initWithLength:(CGFloat)length
								 anchor:(CGFloat)anchor
								 offset:(CGFloat)offset
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

@end


/**
 * This filter provides alternative values when source values are nil or do not reach the border.
 * expandMin/Max controls whether to overwride value if min/max of data is above/below its criteria or to leave them unmodified.
 */
@interface FMSourceFilter : NSObject<FMRangeFilter>

@property (readonly, nonatomic) CGFloat min;
@property (readonly, nonatomic) CGFloat max;
@property (readonly, nonatomic) BOOL	expandMin;
@property (readonly, nonatomic) BOOL	expandMax;

- (instancetype _Nonnull)initWithMinValue:(CGFloat)min
								 maxValue:(CGFloat)max
								expandMin:(BOOL)expandMin
								expandMax:(BOOL)expandMax
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

+ (instancetype _Nonnull)expandWithMin:(CGFloat)min max:(CGFloat)max;
+ (instancetype _Nonnull)ifNullWithMin:(CGFloat)min max:(CGFloat)max;

@end

// sourceまたは現在のmin/maxにpaddingを加える.
// allowShrinkはsourceから計算した新しい値が範囲を狭める場合にその値を使うか否か,
// applyToCurrentMinMaxはpaddingを現在値に加えるかどうか. 例えばAlternativeSourceの次に使う場合は
// 現在のmin/maxが補正されてsourceMin/Maxのように働くため.

/**
 * A filter that adds margin to source(data min/max) and cuurent(given min/max) if specified,
 * compare them, and chooses one for new value.
 * Values of paddingLow/Hight must be >= 0.
 * If shrinkMin is YES, then use dataMin+padding if dataMin+padding < currentMin(+padding)
 *
 * A simple usage is to set shrinkMin/Max to NO and applyToCurrentMinMax to YES.
 * (ignore source min/max and add padding to current min/max)
 */
@interface FMPaddingFilter : NSObject<FMRangeFilter>

@property (readonly, nonatomic) CGFloat paddingLow;
@property (readonly, nonatomic) CGFloat paddingHigh;
@property (readonly, nonatomic) BOOL	shrinkMin;
@property (readonly, nonatomic) BOOL	shrinkMax;
@property (readonly, nonatomic) BOOL	applyToCurrentMinMax;

- (instancetype _Nonnull)initWithPaddingLow:(CGFloat)low
									   high:(CGFloat)high
								  shrinkMin:(BOOL)shrinkLow
								  shrinkMax:(BOOL)shrinkHigh
							 applyToCurrent:(BOOL)apply
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

+ (instancetype)paddingWithLow:(CGFloat)low high:(CGFloat)high;

@end


/**
 * A filter that sets min/max to multiples of given value.
 * Anchor value specifies the starting point.
 * shrinkMin/Max specifies a filter to shrink or expand range.
 */

@interface FMIntervalFilter : NSObject<FMRangeFilter>

@property (readonly, nonatomic) CGFloat anchor;
@property (readonly, nonatomic) CGFloat interval;
@property (readonly, nonatomic) BOOL	shrinkMin;
@property (readonly, nonatomic) BOOL	shrinkMax;

- (instancetype _Nonnull)initWithAnchor:(CGFloat)anchor
							   interval:(CGFloat)interval
							  shrinkMin:(BOOL)shrinkMin
							  shrinkMax:(BOOL)shrinkMax
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

+ (instancetype)filterWithAnchor:(CGFloat)anchor interval:(CGFloat)interval;

@end

/**
 * FMWindowLengthDelegate provides window length in data space, given (accessible) data range and physical size of view(-padding)
 */

@protocol FMWindowLengthDelegate <NSObject>

- (CGFloat)lengthForViewPort:(CGFloat)viewPort
                   dataRange:(CGFloat)length
;

@end

/**
 * FMWindowPositionDelegate determine how to place window inside given data range.
 * 0 means window.minValue = range.minValue, 1 means window.maxValue = range.maxValue.
 */
@protocol FMWindowPositionDelegate <NSObject>

- (CGFloat)positionInRangeWithMin:(CGFloat)minValue
                              max:(CGFloat)maxValue
                           length:(CGFloat)length
;

@end

/**
 * FMWindowFiler class provide the notion of a "viewport" to the given range (the range will be treated as accessble range).
 * A viewport can be moved(pan) and scaled if delegate objects handle events, and of course default implementations do handle them.
 * (Look for FMScaledWindowLength and FMAnchoredWindowPosition)
 *
 * This class (and its delegate) takes the physical size of view and padding into account (not a pixel size).
 */

@interface FMWindowFilter : NSObject<FMRangeFilter>

@property (nonatomic, readonly) FMDimOrientation orientation;
@property (nonatomic, readonly, weak) UIView *_Nullable view;
@property (nonatomic, readonly) FMRectPadding padding;
@property (nonatomic, readonly, weak) id<FMWindowLengthDelegate> _Nullable lengthDelegate;
@property (nonatomic, readonly, weak) id<FMWindowPositionDelegate> _Nullable positionDelegate;

- (instancetype _Nonnull)initWithOrientation:(FMDimOrientation)orientation
                                        view:(UIView * _Nonnull)view
									 padding:(FMRectPadding)padding
                              lengthDelegate:(id<FMWindowLengthDelegate>_Nonnull)lenDelegate
							positionDelegate:(id<FMWindowPositionDelegate>_Nonnull)posDelegate
;

@end

NS_ASSUME_NONNULL_END
