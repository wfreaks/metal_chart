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
#import "Prototypes.h"

// orthogonalがnullableなのは、sharedの場合はprojectionに無関係に設定しなければ動作が担保できないため.
// exclusiveならnonnullである.

/**
 * FMAxisConfiguration protocol object determin where axis and ticks should be drawn in chart using data/view coordinate
 * in every draw loop taking data ranges into account.
 */
@protocol FMAxisConfigurator<NSObject>

- (void)configureUniform:(FMUniformAxisConfiguration * _Nonnull)uniform
		   withDimension:(FMDimensionalProjection * _Nonnull)dimension
			  orthogonal:(FMDimensionalProjection * _Nullable)orthogonal
;

@end


/**
 * FMAxis represents a single axis.
 * It is a pure visual element, and does not modify data ranges at all.
 * An FMAxis instance consists of 'configuration'(where/how an axis and its ticks should be placed) and
 * 'attributes'(width and colors).
 * Grid lines and labels are handled by other classes (They may have references to FMAxis).
 * Configurations (FMAxisConfiguration object) are not meant to be modified manually, leave them to FMAxisConfigurator delegate.
 * (except for properties that the setter methods are defined in FMAxis protocol).
 */

@protocol FMAxis <FMDependentAttachment>

@property (readonly, nonatomic) FMAxisPrimitive *			_Nonnull  axis;
@property (readonly, nonatomic) FMDimensionalProjection *	_Nonnull  dimension;

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

/**
 * In order to share an axis among FMChart instances, subordinate configurator must fullfill below conditions :
 * 1. independent of ranges of orthognal dimension(s)
 * 2. projections the axis resides shares FMDimensionalProjection instance and its dimensional index (position, not an id).
 * if these condictions are not met, then FMUniformAxisConfiguration object may have different values depending on projection.
 * To allow an axis to be shared among FMChart instances, this protocol define method below and hide FMUniformAxisConfiguration instance.
 */
- (FMProjectionCartesian2D * _Nullable)projectionForChart:(MetalChart * _Nonnull)chart;

/**
 * This method is defined because exposing FMUniformAxisConfiguration instances is not possible/reasonable (see above explanation).
 */
- (void)setMinorTickCountPerMajor:(NSUInteger)count;

@end


/**
 * FMExclusiveAxis represents an axis which is not shared by multiple FMChart objects.
 * Basically, you should use an instance of this class, intead of an FMSharedAxis instance.
 * (Sharing an axis is a very complex use case. The purpose of providing FMSharedAxis is to allow you to share texture buffers for labels,
 *  which are much more exepensive than other buffer objects, and in that case dependencies are so complex that you should know everything
 *  in implementations. You should avoid using it when you can do so.)
 */


@interface FMExclusiveAxis : NSObject<FMAxis>

@property (readonly, nonatomic) FMProjectionCartesian2D *	_Nonnull  projection;
@property (readonly, nonatomic) FMDimensionalProjection *	_Nonnull  dimension;

@property (readonly, nonatomic) FMAxisPrimitive *			_Nonnull  axis;
@property (readonly, nonatomic) id<FMAxisConfigurator>		_Nonnull  conf;

/**
 * @param engine
 * @param projection
 * @param dimsensionId id of which dimension this axis represents ([FMDimensionalProjection dimensionId]).
 * @param conf
 */
- (_Nonnull instancetype)initWithEngine:(FMEngine * _Nonnull)engine
							 Projection:(FMProjectionCartesian2D * _Nonnull)projection
							  dimension:(NSInteger)dimensionId
						  configuration:(id<FMAxisConfigurator> _Nonnull)conf
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

@end

/**
 * FMSharedAxis represents an axis that can be shared by multiple FMChart instance.
 * Usage is almost identical to FMExcusiveAxis, but in addition to that, User must explicitly bind
 * projection to chart, and unbind them afterwards.
 * 
 * This class does not use multiple FMUniformAxisConfiguration instances, and therefore, 
 * an instance of FMUnfiromConfiguration will not be updated before drawing a frame.
 * FMSharedAxis does not have a reference to fonfigurator. That means, you are responsible for configuring it.
 */

@interface FMSharedAxis : NSObject<FMAxis>

@property (readonly, nonatomic) FMDimensionalProjection *	_Nonnull  dimension;

@property (readonly, nonatomic) FMAxisPrimitive *			_Nonnull  axis;

// DimensionId ではなく、Index. x/yの位置指定である事に注意.
/**
 * @param engine
 * @param dimension
 * @param index The index (not an id) of dimension this axis resides, in bounded cartesian space (this index must be same for all projections).
 */
- (_Nonnull instancetype)initWithEngine:(FMEngine * _Nonnull)engine
							  dimension:(FMDimensionalProjection * _Nonnull)dimension
						 dimensionIndex:(NSUInteger)index
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

/**
 * A shared axis needs to know which cartesian space to be used to draw in a given chart.
 * You are responsible for binding them to draw the axis in the chart.
 */

- (void)setProjection:(FMProjectionCartesian2D * _Nonnull)projection
			 forChart:(MetalChart * _Nonnull)chart;

/**
 * Obviously you are also responsible for unbinding charts and projections when done.
 * (but it won't harm you even if you do not unbind them actually)
 */
- (void)removeProjectionForChart:(MetalChart * _Nonnull)chart;

@end


/**
 * FMAxisConfigurationBlock class provides a way to FMAxisConfigurator implementations using blocks, 
 * and pre-defined implementations which cover the most of your needs.
 */
typedef void (^FMAxisConfiguratorBlock)(FMUniformAxisConfiguration *_Nonnull axis,
										FMDimensionalProjection *_Nonnull dimension,
										FMDimensionalProjection *_Nullable orthogonal,
										BOOL isFirst
										);

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

/**
 * Creates a configurator that places an axis at an fixed position "in data space" (it can be scrolled by user interactions).
 *
 * @param axisAnchor a value (in the orhogonal dimension) on which an axis will be plcaed.
 */
+ (instancetype _Nonnull)configuratorWithFixedAxisAnchor:(CGFloat)axisAnchor
											  tickAnchor:(CGFloat)tickAnchor
										   fixedInterval:(CGFloat)majorTickInterval
										  minorTicksFreq:(uint8_t)minorPerMajor
;

// 基本は上と同じだが、画面上での軸位置を固定する時に使う.
// 例えばy方向の範囲が[yMin,yMax]の時、axisPos=0としてx軸に設定すると、x軸はy=yMinの位置に表示される.
// 同様に, axisPos=1とすれば、y=yMaxの位置に現れる.

/**
 * Creates a configurator that places an axis based on "view coordinate system".
 *
 * @param axisPosition a value (in the orhogonal direction) on which an axis will be plcaed.
 * (0,0) is at the bottom-left, (1,1)is at the top-right, taking paddings into account.
 */
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

/**
 * Creates a configurator that places an axis based on "view coordinate system", and manages label(tick) intervals using maxTickCount and intervalOfInterval.
 *
 * @param axisPosition a value (in the orhogonal direction) on which an axis will be plcaed, (0,0) is at bottom-left, (1,1)is at top-right. takes padding into account.
 * @param interval an actual (run-time) interval of majtor ticks can be n * interval (n >= 1). Behavior of nagative interval value is undefined.
 */

+ (instancetype _Nonnull)configuratorWithRelativePosition:(CGFloat)axisPosition
											   tickAnchor:(CGFloat)tickAnchor
										   minorTicksFreq:(uint8_t)minorPerMajor
											 maxTickCount:(uint8_t)maxTick
									   intervalOfInterval:(CGFloat)interval
;

@end





