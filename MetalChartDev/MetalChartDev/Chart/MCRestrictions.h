//
//  MCRestrictions.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/10.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCInteractive.h"

@class MCProjectionUpdater;


// MCProjectionUpdaterに複数組み合わせ設定する事でrangeを設定・更新するための構成要素.
// どんな実装でも構わないが、対象のMCDimensionalProjectionのmin/max（現在値）を使うとフィードバックループが発生するので、
// これだけはオススメしない.

@protocol MCRestriction<NSObject>

- (void)updater:(MCProjectionUpdater * _Nonnull)updater
	   minValue:(CGFloat * _Nonnull)min
	   maxValue:(CGFloat * _Nonnull)max
;

@end


// 範囲長を固定する. Anchorの値は-1でmin, +1でmaxを指し、その点を固定した状態で拡大縮小する.
// つまりanchor=-1の場合、minを変更せずmaxのみを動かし、anchor=1ならば中央値を固定してmin,maxを動かす.
// offsetはlengthによらない移動を提供する.
@interface MCLengthRestriction : NSObject<MCRestriction>

@property (readonly, nonatomic) CGFloat length;
@property (readonly, nonatomic) CGFloat anchor;
@property (readonly, nonatomic) CGFloat offset;

- (instancetype _Null_unspecified)initWithLength:(CGFloat)length
										  anchor:(CGFloat)anchor
										  offset:(CGFloat)offset
;

@end


// updaterのsource{Min,Max}Valueがnilの時、あるいは代替値に達しなかった場合には代替値で、
// それ以外の場合にはsourceの値でmin/maxを更新する. このクラスはmin/maxの現在地を「完全に」無視する.
// sourceの値が代替値に達していなくてもsourceの値を使いたい場合はexpand{Min,Max}をNOにする.
// 優先度的に低い方に来るのが普通の使い方だろう.
@interface MCSourceRestriction : NSObject<MCRestriction>

@property (readonly, nonatomic) CGFloat min;
@property (readonly, nonatomic) CGFloat max;
@property (readonly, nonatomic) BOOL    expandMin;
@property (readonly, nonatomic) BOOL    expandMax;

- (instancetype _Null_unspecified)initWithMinValue:(CGFloat)min
										  maxValue:(CGFloat)max
										 expandMin:(BOOL)expandMin
										 expandMax:(BOOL)expandMax
;

@end

// sourceまたは現在のmin/maxにpaddingを加える.
// allowShrinkはsourceから計算した新しい値が範囲を狭める場合にその値を使うか否か,
// applyToCurrentMinMaxはpaddingを現在値に加えるかどうか. 例えばAlternativeSourceの次に使う場合は
// 現在のmin/maxが補正されてsourceMin/Maxのように働くため.
@interface MCPaddingRestriction : NSObject<MCRestriction>

@property (readonly, nonatomic) CGFloat paddingLow;
@property (readonly, nonatomic) CGFloat paddingHigh;
@property (readonly, nonatomic) BOOL    shrinkMin;
@property (readonly, nonatomic) BOOL    shrinkMax;
@property (readonly, nonatomic) BOOL    applyToCurrentMinMax;

- (instancetype _Null_unspecified)initWithPaddingLow:(CGFloat)low
												high:(CGFloat)high
										   shrinkMin:(BOOL)shrinkLow
										   shrinkMax:(BOOL)shrinkHigh
									  applyToCurrent:(BOOL)apply
;

@end



typedef void (^RestrictionBlock)(MCProjectionUpdater *_Nonnull updater, CGFloat * _Nonnull min, CGFloat * _Nonnull max);



@interface MCBlockRestriction : NSObject<MCRestriction>

- (instancetype _Null_unspecified)initWithBlock:(RestrictionBlock _Nonnull)block;

@end

// MCUserInteractiveRestriction - Pan/Zoom操作を実現するコンポーネント.
// 
// 上記概要からわかるように、このクラスは少し毛並みが異なる.
// このクラスだけが他の具体的な実装を持つRestrictionsとは異なり、statefullである。
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
// もしもより細かいレベルのコントロールを行いたいのなら、MCGestureInterpreterの代替を用意すればよい.
// あれはUIGestureRecognizerのtarget selector pairに設定してステートを管理するだけのユーティリティクラスで、
// コアクラス(MetalChart.h内で宣言されるクラス)からは一切参照されない.

@interface MCUserInteractiveRestriction : NSObject<MCRestriction>

@property (readonly, nonatomic) CGFloat orientationRad;
@property (readonly, nonatomic) MCGestureInterpreter * _Nonnull interpreter;

- (instancetype _Null_unspecified)initWithGestureInterpreter:(MCGestureInterpreter * _Nonnull)interpreter
												 orientation:(CGFloat)radian
;

@end





