//
//  FMAxis.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/11.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MetalChart.h"
#import "FMProjections.h"

@class FMEngine;
@class FMUniformLineAttributes;
@class FMAxisPrimitive;
@class FMUniformAxisConfiguration;
@protocol FMAxis;

// orthogonalがnullableなのは、sharedの場合はprojectionに無関係に設定しなければ動作が担保できないため.
// exclusiveならnonnullである.
typedef void (^FMAxisConfiguratorBlock)(FMUniformAxisConfiguration *_Nonnull axis,
										FMDimensionalProjection *_Nonnull dimension,
										FMDimensionalProjection *_Nullable orthogonal,
										BOOL isFirst
										);

@protocol FMAxisConfigurator<NSObject>

- (void)configureUniform:(FMUniformAxisConfiguration * _Nonnull)uniform
		   withDimension:(FMDimensionalProjection * _Nonnull)dimension
			  orthogonal:(FMDimensionalProjection * _Nullable)orthogonal
;

@end





@protocol FMAxis <FMDependentAttachment>

@property (readonly, nonatomic) FMAxisPrimitive *			_Nonnull  axis;
@property (readonly, nonatomic) id<FMAxisConfigurator>		_Nonnull  conf;
@property (readonly, nonatomic) FMDimensionalProjection *	_Nonnull  dimension;

- (void)setMinorTickCountPerMajor:(NSUInteger)count;

// なんでProjectionはChartで切り替えられるのにDimensionは1つなのかと思うかもしれないが、
// 複数Chartで軸を共有する場合、そもそも以下の条件を満たす必要がある.
// ・confがorthogonalに依存しない（別のインスタンスを渡しても常に同じ設定を行う）
// ・共有する複数のChartに対応するprojectionにおいて、必ず軸index(x/y)とdimensionが共有される事
// この条件を満たさない限り、正常な動作は原理的にできない
// (軸indexは設定用の構造体メンバに含まれてしまってるためで厳密には原理的にではないのだが).
//
// このあたり、SharedAxisを使う場合、果たして本当に利用条件を満たしているのか
// 設計者が吟味する事. 面倒ならExclusiveを使うべきである(こちらのほうがずっと単純な作りである)
// ライブラリ自体が整合性をチェックしてAssertする事はまずない.
// 特に軸indexの一貫性は自分で担保する事 (そもそもxy反転する時点でどうかと思うが).
- (FMProjectionCartesian2D * _Nullable)projectionForChart:(MetalChart * _Nonnull)chart;

@end





@interface FMExclusiveAxis : NSObject<FMAxis>

@property (readonly, nonatomic) FMProjectionCartesian2D *	_Nonnull  projection;
@property (readonly, nonatomic) FMDimensionalProjection *	_Nonnull  dimension;

@property (readonly, nonatomic) FMAxisPrimitive *			_Nonnull  axis;
@property (readonly, nonatomic) id<FMAxisConfigurator>		_Nonnull  conf;

- (_Nonnull instancetype)initWithEngine:(FMEngine * _Nonnull)engine
							 Projection:(FMProjectionCartesian2D * _Nonnull)projection
							  dimension:(NSInteger)dimensionId
						  configuration:(id<FMAxisConfigurator> _Nonnull)conf
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

@end


// 字のごとく複数のChartで共有するためのAxisだが、まずはFMAxisのコメントを読む事.
// 次に、単に同じ範囲を指定したいだけならconfiguratorとconfを指定するだけで済むし、
// 細かいコントロールが効く事も理解した上で使う事.
// 今のところの使い道は、AxisLabelが描画バッファとしてそれなりの量のGPUメモリを確保するとか、
// 文字描画処理がCPUを食いつぶすとかいった事への対処くらいである.
// ＊同じ時間軸を共有する複数グラフをTableViewで複数ならべる、というのが該当ケース.
// 　ラベルの色を変えるとか云った事が必要になる場合は、labelだけでなくaxisも分けた方がわかりやすい.

@interface FMSharedAxis : NSObject<FMAxis>

@property (readonly, nonatomic) FMDimensionalProjection *	_Nonnull  dimension;

@property (readonly, nonatomic) FMAxisPrimitive *			_Nonnull  axis;
@property (readonly, nonatomic) id<FMAxisConfigurator>		_Nonnull  conf;

// 非常に遺憾な事ながら、軸を「画面上の位置固定」にすると共有できないというわりかしヤバ目の
// 設計上のミス（構造体がデータ空間での位置固定をデフォルトにしたため）をどうにか回避するために、
// 直交軸に依存する場合の挙動を変更する必要がある.
// そもそもこれはバグではないのでそのために設計を曲げるのはどうかという気もするが、
// 回避策を用意する事自体は問題ないと考える(使うかは使用者の判断に委ねる)
// この方法を使って回避する場合、60fpsでグラフ２個同時に走らせた場合、画面表示が乱れるかもしれない.
// (要は同期上の問題が存在するという事.)
// 多分ちゃんとuniformを(あるいはprimitiveごと)chart毎に分けるべきなのだろう.

@property (nonatomic) BOOL											needsOrhogonal;

// DimensionId ではなく、Index. x/yの位置指定である事に注意.
- (_Nonnull instancetype)initWithEngine:(FMEngine * _Nonnull)engine
							  dimension:(FMDimensionalProjection * _Nonnull)dimension
						 dimensionIndex:(NSUInteger)index
						  configuration:(id<FMAxisConfigurator> _Nonnull)conf
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

- (void)setProjection:(FMProjectionCartesian2D * _Nonnull)projection
			 forChart:(MetalChart * _Nonnull)chart;
- (void)removeProjectionForChart:(MetalChart * _Nonnull)chart;

@end


// 全ての項目を自由に、かつ効率的にコントロールするためのクラス（だが宣言的ではない）
// 固定機能クラスも作ろうと思ったけど全部代用できるのでやめた.
@interface FMBlockAxisConfigurator : NSObject<FMAxisConfigurator>

- (instancetype _Nonnull)initWithBlock:(FMAxisConfiguratorBlock _Nonnull)block
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;


// 1度だけ与えられた値をそのままconfへ設定する.
// axisAnchorはデータ空間での位置なので、グラフを動かすと一緒に動く.
// 範囲外へ出てしまう時に軸を消すという動作は現在実装されていない（シザーテストは描画が崩れ、またラベルなどへも影響する）
// ので、範囲外の時は端に留める挙動にしてあることに注意.
// (結果としてこの実装は直交する次元の範囲に依存する)
+ (instancetype _Nonnull)configuratorWithFixedAxisAnchor:(CGFloat)axisAnchor
											  tickAnchor:(CGFloat)tickAnchor
										   fixedInterval:(CGFloat)majorTickInterval
										  minorTicksFreq:(uint8_t)minorPerMajor
;

// 基本は上と同じだが、画面上での軸位置を固定する時に使う.
// 例えばy方向の範囲が[yMin,yMax]の時、axisPos=0としてx軸に設定すると、x軸はy=yMinの位置に表示される.
// 同様に, axisPos=1とすれば、y=yMaxの位置に現れる.
+ (instancetype _Nonnull)configuratorWithRelativePosition:(CGFloat)axisPosition
											   tickAnchor:(CGFloat)tickAnchor
											fixedInterval:(CGFloat)tickInterval
										   minorTicksFreq:(uint8_t)minorPerMajor
;


// ラベルなどの数を一定の範囲に抑えながら、その値が半端な値にならないように調整するためのクラス。
// つまり範囲長が連続的に変化していく際、intervalがステップ上の変化をしつつラベルの数を一定範囲に
// 抑える.
// position, anchor, minorTicksは他のと変わらない.
// max はちょっと注意が必要で、範囲長とintervalが決まっていてもanchorによっては
// ラベル数が変化しうる事を考慮しない、ここでは可能な値のうち高い方、つまり両端にラベルが来る場合を取る.
// maxの場合のintervalを逆算し、その値よりも大きくかつintervalOfIntervalの倍数となるものを取る.

+ (instancetype _Nonnull)configuratorWithRelativePosition:(CGFloat)axisPosition
											   tickAnchor:(CGFloat)tickAnchor
										   minorTicksFreq:(uint8_t)minorPerMajor
											 maxTickCount:(uint8_t)maxTick
									   intervalOfInterval:(CGFloat)interval
;

@end





