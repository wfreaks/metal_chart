//
//  FMRangeFilters.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/10.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMInteractive.h"
#import "MetalChart.h"


// FMProjectionUpdaterに複数組み合わせ設定する事でrangeを設定・更新するための構成要素.
// どんな実装でも構わないが、対象のFMDimensionalProjectionのmin/max（現在値）を使うとフィードバックループが発生するので、
// これだけはオススメしない.
// 基本的にはフィルタを重ねていくイメージ, inputは入力されたデータのmin/max、outputは「画面上に表示される」min/maxとなる.
// ただし、入力データは正確にはinputではなく、それを取り込むフィルタを入れる事で考慮できるようになっている
// (複数のフィルタで考慮したい時もあるだろうし、純粋なinputは+/-CGFloatMaxとなっている)


@protocol FMRangeFilter<NSObject>

- (void)updater:(FMProjectionUpdater * _Nonnull)updater
	   minValue:(CGFloat * _Nonnull)min
	   maxValue:(CGFloat * _Nonnull)max
;

@end

// 何も値を変更せず、記録と露出だけするFilter. ちゃんと使い道はある.
// というより、他のFilterはほぼ全てimmutableにしてあるため、現在の値を見たければこれを使う事
// (値をいじりつつ記録するとかすると、モデルがややこしくなる上にパフォーマンス上のメリットもほぼ無い)
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


// updaterのsource{Min,Max}Valueがnilの時、あるいは代替値に達しなかった場合には代替値で、
// それ以外の場合にはsourceの値でmin/maxを更新する. このクラスはmin/maxの現在地を「完全に」無視する.
// sourceの値が代替値に達していなくてもsourceの値を使いたい場合はexpand{Min,Max}をNOにする.
// 優先度的に低い方(入力側)に来るのが普通の使い方だろう.
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

@end

// sourceまたは現在のmin/maxにpaddingを加える.
// allowShrinkはsourceから計算した新しい値が範囲を狭める場合にその値を使うか否か,
// applyToCurrentMinMaxはpaddingを現在値に加えるかどうか. 例えばAlternativeSourceの次に使う場合は
// 現在のmin/maxが補正されてsourceMin/Maxのように働くため.
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

@end


/*
 * 両端を(anchor + (n*interval))に調整するためのクラス.
 * アンカー、倍数、min/maxそれぞれをどちらへ調整するかのパラメータのみ.
 * shrinkはYESならば範囲が狭くなる方向へ調整して揃える.
 * このクラスは直接ソースの値を参照しない、そういう事は他のFilterと繋げて行う
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

@end


typedef NS_ENUM(NSInteger, FMDimOrientation) {
    FMDimOrientationHorizontal = 0,
    FMDimOrientationVertical = 1,
};

// data空間とview空間を結びつける, 本質的にはLengthFileterに近い.
// このクラスはviewというより、物理サイズを意識したもの. (名前としてはこの方がわかりやすいかと)
// anchorは[0, 1]で指定し、dataとviewのそれが重なるように配置する.
// viewSizeが変わったら当然projectionをアップデートする必要がある.
// scale は以下の計算式に従ってdata空間でのlengthを計算する際に使われる.
// l_data = scale * (l_view - padding)
// また、view空間ではy軸が反転するが、基本的にanchorとしては1が上となる事に注意.
// 凄まじくパラメータ数多いが、二つの空間を結合して一意に決定するにはこのくらい必要.

@interface FMViewSizeFilter : NSObject<FMRangeFilter>

@property (nonatomic, readonly) FMDimOrientation orientation;
@property (nonatomic, readonly, weak) UIView *_Nullable view;
@property (nonatomic, readonly) CGFloat dataAnchor;
@property (nonatomic, readonly) CGFloat viewAnchor;
@property (nonatomic, readonly) CGFloat scale;
@property (nonatomic, readonly) RectPadding padding;

- (instancetype _Nonnull)initWithOrientation:(FMDimOrientation)orientation
                                        view:(UIView * _Nonnull)view
                                  dataAnchor:(CGFloat)dataAnchor
                                  viewAnchor:(CGFloat)viewAnchor
                                       scale:(CGFloat)scale
									 padding:(RectPadding)padding
;

@end



typedef void (^FilterBlock)(FMProjectionUpdater *_Nonnull updater, CGFloat * _Nonnull min, CGFloat * _Nonnull max);



@interface FMBlockFilter : NSObject<FMRangeFilter>

- (instancetype _Nonnull)initWithBlock:(FilterBlock _Nonnull)block
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

@end

// FMUserInteractiveFilter - Pan/Zoom操作を実現するコンポーネント.
// 
// 上記概要からわかるように、このクラスは少し毛並みが異なる.
// このクラスだけが他の具体的な実装を持つFiltersとは異なり、statefullである。
// （実際はstateを管理しているのはinterpreterで、このクラスはそれを反映する）.
// また本来結びつかないはずのDimProjectionとUI操作を結合するために、orientationを指定している.
// 対象のDimProjectionがorientationと一致しない場合はおかしな挙動となる事に注意が必要である.
//
// 補足しておくと、１つのプロットエリアに複数の空間/写像を持てる構造とUI操作の曖昧さから、その対応付けで
// どこか無理をする必要は必ず存在し、orientationを用いない自然な対応付けは構造に制約を付加する事無しには
// 実現ができない. (projection A/Bにそれぞれ0/1番目の次元として使われる共通のdimProjectionへのフィードバックは自然な方法では
// 絶対に不可能であり、こういった構造を弾くチェック処理および方向を推定する処理が必要となる. 多分、誰も得をしないだろう)
// そういった経緯からこうした方法を取っている. その分挙動は明快であり、各自の判断で自由に制御すれば良い.
//
// このクラス内でリミットの設定は行わない. ステートの管理はinterpreterが行っている(効率上)ため、これを
// 適用する際に弄り回すと、ステートと実際のレンジとの間にギャップが生まれる（リミット以上の拡大もステート上は可能になる）.
// 結果として例えば拡大率200%でリミットをかけてステートが400%に達したとき、縮小は400%->200%までの間は無反応になる.
// 
// もしもより細かいレベルのコントロールを行いたいのなら、FMGestureInterpreterの代替を用意すればよい.
// あれはUIGestureRecognizerのtarget selector pairに設定してステートを管理するだけのユーティリティクラスで、
// コアクラス(MetalChart.h内で宣言されるクラス)からは一切参照されない.
// ただしこのクラスはGestureInterpreterありきのものなので、Filterも自分で書き直す必要がある.

@interface FMUserInteractiveFilter : NSObject<FMRangeFilter>

@property (readonly, nonatomic) CGFloat orientationRad;

// updater -> Filter(self) -> interpreter -> interaction -> updater と循環参照になる.
// 実際こいつが所有権をもつのは微妙.
@property (readonly, nonatomic, weak) FMGestureInterpreter * _Nullable interpreter;

- (instancetype _Nonnull)initWithGestureInterpreter:(FMGestureInterpreter * _Nonnull)interpreter
										orientation:(CGFloat)radian
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

@end

