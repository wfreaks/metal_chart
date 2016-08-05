//
//  FMAxis.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/11.
//  Copyright © 2015 Keisuke Mori. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMMetalChart.h"
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
- (FMProjectionCartesian2D * _Nullable)projectionForChart:(FMMetalChart * _Nonnull)chart;

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
			 forChart:(FMMetalChart * _Nonnull)chart;

/**
 * Obviously you are also responsible for unbinding charts and projections when done.
 * (but it won't harm you even if you do not unbind them actually)
 */
- (void)removeProjectionForChart:(FMMetalChart * _Nonnull)chart;

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

@interface FMBlockAxisConfigurator : NSObject<FMAxisConfigurator>

- (instancetype _Nonnull)initWithBlock:(FMAxisConfiguratorBlock _Nonnull)block
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;


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





