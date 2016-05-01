//
//  FMRangeFilters.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/10.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MetalChart.h"
#import "Prototypes.h"

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

// これまではデータ空間だけで調整が可能な場合には適用可能なものが多いが、
// 現実的にはViewを意識したり、ユーザ操作等を考慮した形にする必要がある.
// FMWindowFilterとは描画されないが潜在的に存在している、アクセス可能なデータ空間上の領域の
// 一部を切り取って表示するための窓として働く.
// すべてのユースケースに対応する実装は無理だと判断したため、ここでもプロトコルを用いる事にした.
// これらの実装はユーザ操作を考慮するように作るため、別のファイルにおく.
// 別の方法で実装しようかと試みたが、正直失敗したと言って差し支えない結果になった.

@protocol FMWindowLengthDelegate <NSObject>

- (CGFloat)lengthForViewPort:(CGFloat)viewPort
                   dataRange:(CGFloat)length
;

@end

@protocol FMWindowPositionDelegate <NSObject>

- (CGFloat)positionInRangeWithMin:(CGFloat)minValue
                              max:(CGFloat)maxValue
                           length:(CGFloat)length
;

@end


@interface FMWindowFilter : NSObject<FMRangeFilter>

@property (nonatomic, readonly) FMDimOrientation orientation;
@property (nonatomic, readonly, weak) UIView *_Nullable view;
@property (nonatomic, readonly) RectPadding padding;
@property (nonatomic, readonly, weak) id<FMWindowLengthDelegate> _Nullable lengthDelegate;
@property (nonatomic, readonly, weak) id<FMWindowPositionDelegate> _Nullable positionDelegate;

- (instancetype _Nonnull)initWithOrientation:(FMDimOrientation)orientation
                                        view:(UIView * _Nonnull)view
									 padding:(RectPadding)padding
                              lengthDelegate:(id<FMWindowLengthDelegate>_Nonnull)lenDelegate
							positionDelegate:(id<FMWindowPositionDelegate>_Nonnull)posDelegate
;

@end



typedef void (^FilterBlock)(FMProjectionUpdater *_Nonnull updater, CGFloat * _Nonnull min, CGFloat * _Nonnull max);



@interface FMBlockFilter : NSObject<FMRangeFilter>

- (instancetype _Nonnull)initWithBlock:(FilterBlock _Nonnull)block
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

@end


