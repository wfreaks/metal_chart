//
//  FMUtility.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/09/20.
//  Copyright © 2015 Keisuke Mori. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FMAxisLabel.h"
#import "FMRenderables.h"
#import "FMRenderablesAux.h"
#import "Prototypes.h"
#import "Lines.h"
#import "Rects.h"
#import "Points.h"

NS_ASSUME_NONNULL_BEGIN

// モジュラーな設計を心がけると、使いかたの幅が広がると同時に、クラス階層と関係性の理解を強制されるが、
// アプリケーションコードはある意味では迂遠なものになる（実際にはそれが正しい姿だが、往々にして典型的なコードを要求される）。
// そのあたりの不満を解消するためのルーチン集がここに集められる.
// また、クラス関係を理解するためのエントリポイントとしての意味もある.

/*
 * Classes defined in this file are utility class.
 * Although core components are flexible and there are solid reasons for the design,
 * It is not easy nor reasonable to repeat lines of allocating and configuring them in application codes.
 * Following classes shorten your codes of typical use, and make it easy to understand core components.
 */

/**
 * A wrapper class for dimension and its range updater.
 */

@interface FMDimension : NSObject

@property (nonatomic, readonly) FMDimensionalProjection *dim;
@property (nonatomic, readonly) FMProjectionUpdater *updater;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

+ (instancetype)dimensionWithId:(NSInteger)dimensionId
                        filters:(NSArray<id<FMRangeFilter>>*)filters
;

- (void)addValue:(CGFloat)value;
- (void)updateRange;
- (void)clearValues;

@end


/**
 * A wrapper class for FMProjectionCartesian2D and its dimensions.
 */
@interface FMSpace2D : NSObject

@property (nonatomic, readonly) FMProjectionCartesian2D *space;
@property (nonatomic, readonly) FMDimension *x;
@property (nonatomic, readonly) FMDimension *y;
@property (nonatomic, weak) FMMetalView *metalView;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

+ (instancetype)spaceWithDimensionX:(FMDimension*)x
                                  Y:(FMDimension*)y
                             engine:(FMDeviceResource*)resource;

- (void)addValueX:(CGFloat)x Y:(CGFloat)y;
- (void)clearValues;
- (void)updateRanges;

- (BOOL)containsDimension:(FMDimension*)dim;

@end


/**
 * FMChartConfigurator helps you configure a chart by providing various wrapper methods.
 * A configurator allocates, reatains and manage components and relations.
 * It shortens your application codes in most cases, but does not provide any extra functionality.
 * (Using it can spoil flexibility of underlying components in some cases)
 *
 * Using, reading the implementation and writing your own configurator depending on your needs
 * will help you understand concepts, designs and usage of FMChart components.
 */

@interface FMChartConfigurator : NSObject

@property (readonly, nonatomic) NSArray<FMDimension*> *dimensions;
@property (readonly, nonatomic) NSArray<FMSpace2D*> *space;
@property (readonly, nonatomic) FMMetalChart *chart;
@property (readonly, nonatomic) FMMetalView * _Nullable view;
@property (readonly, nonatomic) FMEngine *engine;
@property (readonly, nonatomic) NSInteger preferredFps;

@property (readonly, nonatomic) FMAnimator *animator;
@property (readonly, nonatomic) FMGestureDispatcher *dispatcher;

// インスタンス化するといろいろ面倒な時、とりあえずFMMetalViewの初期設定を行うためのメソッド.
+ (void)configureMetalView:(FMMetalView *)view
			  preferredFps:(NSInteger)fps
                   surface:(FMSurfaceConfiguration *)surface
;

// fps <= 0 では setNeedsRedraw がセットされた時のみ描画するようにMTKViewを調整する.
- (instancetype)initWithChart:(FMMetalChart *)chart
                       engine:(FMEngine * _Nullable)engine
                         view:(FMMetalView * _Nullable)view
                 preferredFps:(NSInteger)fps
NS_DESIGNATED_INITIALIZER;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

- (FMDimension * _Nullable)dimWithId:(NSInteger)dimensionId;

- (FMDimension *)createDimWithId:(NSInteger)dimensionId
                         filters:(NSArray<id<FMRangeFilter>>* _Nullable)filters
;

- (void)clearValuesForAllDimensions;

- (FMSpace2D *)spaceWithDimX:(FMDimension*)x Y:(FMDimension*)y;
- (FMSpace2D *_Nullable)findSpaceWithIdX:(NSInteger)x Y:(NSInteger)y;

- (void)bindGestureRecognizersPan:(FMPanGestureRecognizer * _Nullable)pan
							pinch:(UIPinchGestureRecognizer * _Nullable)pinch
;

- (FMWindowFilter* _Nullable)addWindowToDim:(FMDimension *)dim
									 length:(FMScaledWindowLength *)length
								   position:(FMAnchoredWindowPosition *)position
								 horizontal:(BOOL)horizontal
;

- (FMExclusiveAxis * _Nullable)addAxisToDimWithId:(NSInteger)dimensionId
                                      belowSeries:(BOOL)below
                                     configurator:(id<FMAxisConfigurator>)configurator
                                            label:(FMAxisLabelDelegateBlock _Nullable)block
;

- (FMExclusiveAxis * _Nullable)addAxisToDimWithId:(NSInteger)dimensionId
                                      belowSeries:(BOOL)below
                                     configurator:(id<FMAxisConfigurator>)configurator
                                   labelFrameSize:(CGSize)size
                                 labelBufferCount:(NSUInteger)count
                                            label:(FMAxisLabelDelegateBlock _Nullable)block
;

// 上記２つのメソッドにはAxisLabelへアクセスする手段がない・・・ので、検索して返す必要がある.
- (NSArray<FMAxisLabel *> * _Nullable)axisLabelsToAxis:(id<FMAxis>)axis;

// LineDrawHookは強力なツールだが、使いかたが非常にわかりにくい（自分でも忘れる）ので、よくある一つをシナリオとして加える.
- (id<FMLineDrawHook>)setRoundRectHookToLabel:(FMAxisLabel*)label
										color:(UIColor*)color
									   radius:(CGFloat)radius
									   insets:(CGSize)insets
;

- (FMPlotArea *)addPlotAreaWithColor:(UIColor *)color;

- (FMGridLine * _Nullable)addGridLineToDimensionWithId:(NSInteger)dimensionId
										   belowSeries:(BOOL)below
												anchor:(CGFloat)anchorValue
											  interval:(CGFloat)interval
;

// 以下のFMRenderable系の追加メソッドは適合するLineSeriesなどを返さずprimitiveを返しているが、
// これはLineSeriesなどはほとんど抽象化されラッパーとして機能しており、これを返すと細かいコントロールができないため.
// 各々適切に処理されてるので気にする必要はない.

- (FMLineSeries<FMOrderedPolyLinePrimitive*> *)addLineToSpace:(FMSpace2D *)space
													   series:(FMOrderedSeries *)series
;

- (FMLineSeries<FMOrderedAttributedPolyLinePrimitive*> *)addAttributedLineToSpace:(FMSpace2D *)space
																		   series:(FMOrderedAttributedSeries *)series
															   attributesCapacity:(NSUInteger)capacity
;

- (FMUniformPointAttributes*)setPointToLine:(FMOrderedPolyLinePrimitive*)line
;

- (FMBarSeries<FMOrderedBarPrimitive *>*)addBarToSpace:(FMSpace2D *)space
								  series:(FMOrderedSeries *)series
;

- (FMBarSeries<FMOrderedAttributedBarPrimitive *>*)addAttributedBarToSpace:(FMSpace2D *)space
													  series:(FMOrderedAttributedSeries *)series
										  attributesCapacity:(NSUInteger)capacity
;

- (FMPointSeries<FMOrderedPointPrimitive *>*)addPointToSpace:(FMSpace2D *)space
									  series:(FMOrderedSeries *)series
;

- (FMPointSeries<FMOrderedAttributedPointPrimitive *>*)addAttributedPointToSpace:(FMSpace2D *)space
														  series:(FMOrderedAttributedSeries *)series
											  attributesCapacity:(NSUInteger)capacity
;

- (void)removeRenderable:(id<FMRenderable>)renderable;

- (FMBlockRenderable *)addBlockRenderable:(FMRenderBlock)block;

- (FMOrderedSeries *)createSeries:(NSUInteger)capacity
;

- (FMOrderedAttributedSeries *)createAttributedSeries:(NSUInteger)capacity
;


- (FMProjectionPolar *)addPolarSpace;
;

- (FMPieDoughnutSeries *)addPieSeriesToSpace:(FMProjectionPolar *)space
											 capacity:(NSUInteger)capacity
;

// protocolを使ったdelegate/hookなどを良く実装するため、外側でretainしておく必要が
// 出る事が多いが、実際そのためにプロパティ増やすとかないわーな時に使う.
// 決して良い方法ではないし何回も通るコードパスで使用するべきではないが, 結構便利だったりする.
- (void)addRetainedObject:(id)object;


@end

NS_ASSUME_NONNULL_END


