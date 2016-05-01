//
//  FMInteractive.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/22.
//  Copyright © 2015年 freaks. All rights reserved.
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

- (void)dispatcher:(FMGestureDispatcher*_Nonnull)dispatcher scale:(CGFloat)factor timestamp:(CFAbsoluteTime)timestamp event:(FMGestureEvent)event;

@end


// GestureRecognizerからの通知をうけ、適切に処理したのちにイベントを通知するための
// オブジェクト. recognizerの癖を吸収するための処理のためにstateを持ちはするが、
// それもジェスチャー（及び慣性アニメーション）のライフサイクルを超えないように作ってある.
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



// 物理サイズをベースにしたscale(320あたりデータ空間の長さ10といった具合)に
// 着目して窓長を決める. viewからpaddingを除いたサイズをlv, data range長をldとした時,
// ld = scale * lv
// であり、scaleを上げると感覚的にはデータ空間を切り取る窓は長くなる.
@interface FMScaledWindowLength : NSObject <FMWindowLengthDelegate, FMScaleGestureListener>

@property (nonatomic, readonly) CGFloat currentScale;
@property (nonatomic, readonly) CGFloat minScale;
@property (nonatomic, readonly) CGFloat maxScale;
@property (nonatomic, readonly) CGFloat defaultScale;

@property (nonatomic, weak) MetalView *_Nullable view;
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
@interface FMAnchoredWindowPosition : NSObject <FMWindowPositionDelegate, FMPanGestureListener>

@property (nonatomic, readonly) CGFloat anchor; // inputが変化した時のwindowのanchor.
@property (nonatomic, readonly) CGFloat currentValue; // anchorの現在data空間上での値.
@property (nonatomic, readonly) CGFloat defaultValue;
@property (nonatomic, readonly, weak) FMScaledWindowLength * _Nullable length; // panGestureの解釈にはどうやっても現在のscaleを必要とするため.

@property (nonatomic, weak) MetalView *_Nullable view;
@property (nonatomic, weak) FMProjectionUpdater *_Nullable updater;

- (instancetype _Nonnull)initWithAnchor:(CGFloat)anchor
						   defaultValue:(CGFloat)value
						   windowLength:(FMScaledWindowLength* _Nonnull)length
;

- (void)reset;

@end





@protocol FMPanGestureRecognizerDelegate<NSObject>

- (void)didBeginTouchesInRecognizer:(FMPanGestureRecognizer * _Nonnull)recognizer;

@end


@interface FMPanGestureRecognizer : UIPanGestureRecognizer

@property (nonatomic, weak) IBOutlet id<FMPanGestureRecognizerDelegate> _Nullable recognizerDelegate;

@end

