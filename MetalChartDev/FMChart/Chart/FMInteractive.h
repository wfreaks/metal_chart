//
//  FMInteractive.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/22.
//  Copyright © 2015 Keisuke Mori. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Prototypes.h"
#import "FMRangeFilters.h"

// 引数として渡されるのはいづれもフレーム間での差異（スケールはview空間のそれ、ただしy軸は上向き）であり、
// 積算はリスナー側でする事（そもそも無次元の積算値を作ると解釈が非常に面倒で、さらにその積算値の値を操作したり
// データに依存して制限をかけたりという話になると凄まじく面倒になって一度実装を破棄した）

@class FMGestureDispatcher;

typedef NS_ENUM(NSInteger, FMGestureEvent) {
	FMGestureEventBegin,
	FMGestureEventProgress,
	FMGestureEventEnd,
};

@protocol FMPanGestureListener <NSObject>

- (void)dispatcher:(FMGestureDispatcher*_Nonnull)dispatcher
			   pan:(CGFloat)delta
		  velocity:(CGFloat)velocity
		 timestamp:(CFAbsoluteTime)timestamp
			 event:(FMGestureEvent)event;

@end

@protocol FMScaleGestureListener <NSObject>

- (void)dispatcher:(FMGestureDispatcher*_Nonnull)dispatcher
			 scale:(CGFloat)factor
		  velocity:(CGFloat)velocity
		 timestamp:(CFAbsoluteTime)timestamp
			 event:(FMGestureEvent)event;

@end

/**
 * FMGestureDispatcher processes pan / scale gestures dispatched from UIScaleGestureRecognizer and FMPanGestureRecognizer,
 * then dispatches processed data to achieve panning / scaling of chart (projection).
 *
 * In order for an disptcher instance to work, you should set recognizers and register listeners you want to use.
 * A dispatcher does not use its animator property, but its listeners might use it.
 * (FMAnchoredWindowPosition does so to provide pan animation)
 */
@interface FMGestureDispatcher : NSObject

@property (strong, nonatomic) FMPanGestureRecognizer * _Nullable panRecognizer;
@property (strong, nonatomic) UIPinchGestureRecognizer * _Nullable pinchRecognizer;
@property (nonatomic, weak) FMAnimator * _Nullable animator;

- (instancetype _Nonnull)initWithPanRecognizer:(FMPanGestureRecognizer * _Nullable)pan
							   pinchRecognizer:(UIPinchGestureRecognizer * _Nullable)pinch
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

- (void)addPanListener:(id<FMPanGestureListener>_Nonnull)listener
		   orientation:(FMDimOrientation)orientation
;

- (void)addScaleListener:(id<FMScaleGestureListener>_Nonnull)listener
			 orientation:(FMDimOrientation)orientation
;

- (void)removeAllListeners;

@end

/**
 * FMScaledWindowLength class is an FMWindowLengthDelegate implementation that handles scaling events dispatched from 
 * an FMGestureDispatcher instance. (It does not support animations)
 * scale properties define window length in data space(l_d) based on below equation with window length in view coordinates(l_v) :
 * l_d = l_v * scale
 * currentScale property is set to defaultScale on creating and resetting it.
 *
 * You must provide an updater (and an metal view if it set to event-driven mode) to update screen content automatically.
 */
@interface FMScaledWindowLength : NSObject <FMWindowLengthDelegate, FMScaleGestureListener>

@property (nonatomic, readonly) CGFloat currentScale;
@property (nonatomic, readonly) CGFloat minScale;
@property (nonatomic, readonly) CGFloat maxScale;
@property (nonatomic, readonly) CGFloat defaultScale;

@property (nonatomic, weak) FMMetalView *_Nullable view;
@property (nonatomic, weak) FMProjectionUpdater *_Nullable updater;

- (instancetype _Nonnull)initWithMinScale:(CGFloat)min
                                 maxScale:(CGFloat)max
                             defaultScale:(CGFloat)def
;

- (void)reset;

@end


// inputはdata range, そしてwindow length.
// outputはシンプルだが、inputがimutableである仮定をしなければ、理想的な振る舞いを考えるのは難しい.
// このクラスはシンプルに、窓内で相対的なAnchorを決め、このanchorが指すデータ空間での位置を極力安定させる動作をする.

// anchorが差すcurrentValueはrange+position+lengthで一意となりその逆も成立する、それを利用したのがこのクラスだが、
// 初期ではcurrentValueとpositionの２つが未知となるので、どちらかを指定してやる必要がある.
// これはpositionを指定してcurrentValueを確定させるためのブロック. もちろん戻り値はvalueではなくposition.

/**
 * Parameters and return value are equivalent to those of FMAnchoredWindowPosition.
 */
typedef CGFloat (^FMWindowPositionBlock)(CGFloat min, CGFloat max, CGFloat len);

/**
 * FMAnchoredWindowPosition class is an FMWindowPositionDelegate implementation that handles pan events dispatched from
 * FMGestureDispatcher, animations, and screen rotation.
 * It must be used with an FMScaledWindowLength instance.
 *
 * The basic idea is that the window has an anchor which sits on same position(value) during changes in view size and data range.
 * (otherwise behavior on size/range changes is implementation dependent)
 *
 * Anchor value of 0 represents an anchor at the left(bottom) edge of window, and 1 at the right(top).
 * currentValue represents where an anchor is currently placed at in data space, but it may be invalid (uninitialized).
 * To determine an initial value of currentValue property, you should provide a FMWindowPositionBlock.
 *
 * You must provide an updater (and an metal view if it set to event-driven mode) to update screen content automatically.
 */

@interface FMAnchoredWindowPosition : NSObject <FMWindowPositionDelegate, FMPanGestureListener>

@property (nonatomic, readonly) CGFloat anchor; // inputが変化した時のwindowのanchor.
@property (nonatomic, readonly) CGFloat currentValue; // anchorの現在data空間上での値.
@property (nonatomic, readonly) BOOL invalidated; // currentValueが有効かどうか
@property (nonatomic, copy)     FMWindowPositionBlock _Nonnull valueInitializer; // currentValueを初期化するために必要なブロック.

@property (nonatomic, readonly, weak) FMScaledWindowLength * _Nullable length; // panGestureの解釈にはどうやっても現在のscaleを必要とするため.

@property (nonatomic, weak) FMMetalView *_Nullable view;
@property (nonatomic, weak) FMProjectionUpdater *_Nullable updater;

- (instancetype _Nonnull)initWithAnchor:(CGFloat)anchor
						   windowLength:(FMScaledWindowLength* _Nonnull)length
					   valueInitializer:(FMWindowPositionBlock _Nonnull)initializer
;

/**
 * creates a value initializer block that returns a value of anchor regardless of given data range.
 */
- (instancetype _Nonnull)initWithAnchor:(CGFloat)anchor
						   windowLength:(FMScaledWindowLength* _Nonnull)length
						defaultPosition:(CGFloat)defaultPosition
;

/**
 * Invalidates currentValue property and force resetting position.
 */
- (void)reset;

@end



@protocol FMPanGestureRecognizerDelegate<NSObject>

- (void)didBeginTouchesInRecognizer:(FMPanGestureRecognizer * _Nonnull)recognizer;

@end

/**
 * A UIPanGestureRecognizer instance does not dispatch events at beginning of touches, thus using it disables stopping pan animation by a tap.
 */

@interface FMPanGestureRecognizer : UIPanGestureRecognizer

@property (nonatomic, weak) IBOutlet id<FMPanGestureRecognizerDelegate> _Nullable recognizerDelegate;

@end

