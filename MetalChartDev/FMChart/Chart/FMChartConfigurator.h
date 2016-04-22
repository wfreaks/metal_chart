//
//  FMUtility.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/09/20.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>

// モジュラーな設計を心がけると、使いかたの幅が広がると同時に、クラス階層と関係性の理解を強制されるが、
// アプリケーションコードはある意味では迂遠なものになる（実際にはそれが正しい姿だが、往々にして典型的なコードを要求される）。
// そのあたりの不満を解消するためのルーチン集がここに集められる.
// また、クラス関係を理解するためのエントリポイントとしての意味もある.

#import "FMAxisLabel.h"
#import "FMRenderables.h"
#import "FMRenderablesAux.h"
#import "Prototypes.h"


typedef FMProjectionUpdater * _Nullable (^DimensionConfigureBlock)(NSInteger dimensionID);

// Chartに対しての設定を簡潔にするためのオブジェクト.
// ただし、効率性や柔軟性を重視するなら、このクラスを使わずに手で設定することをお勧めする.
// (初期設定時の負荷など描画に比べれば微々たるものなので、効率が問題になることはまずないとは思う)
// また大体のことはこのクラスを使ってできるようにするつもりだが、凝った事をやろうとしているなら、
// 迷わずより低いレベルのクラスを直接使う事をお勧めする(綺麗により細かいコントロールができる魔法のクラスなんて存在しないし、
// 文字数より細かい制御など原理的にできる訳がない)

// またこのクラスの性質上、オブジェクトを作成・設定した後戻り値として返す場合でも、内部的にretainしているものが多い.
// わざわざretainする為だけにプロパティ追加を強制するのは非合理的だからである.
// 特にProjectionUpdaterやGestureInterpreter、デリゲートのデフォルト実装が該当する事が多いが、これはそもそもコアコンポーネントで
// サポートされる仕組みではない事が大きく影響している. またデリゲートをブロックベースで実装できるようにしているものなどは不可避である.

@interface FMChartConfigurator : NSObject

@property (readonly, nonatomic) NSArray<FMDimensionalProjection*> * _Nonnull dimensions;
@property (readonly, nonatomic) NSArray<FMProjectionUpdater*> * _Nonnull updaters;
@property (readonly, nonatomic) NSArray<FMProjectionCartesian2D*> * _Nonnull space;
@property (readonly, nonatomic) MetalChart * _Nonnull chart;
@property (readonly, nonatomic) MetalView * _Nullable view;
@property (readonly, nonatomic) FMEngine * _Nonnull engine;
@property (readonly, nonatomic) NSInteger preferredFps;

@property (readonly, nonatomic) FMAnimator * _Nonnull animator;

// インスタンス化するといろいろ面倒な時、とりあえずMetalViewの初期設定を行うためのメソッド.
+ (void)configureMetalView:(MetalView * _Nonnull)view
			  preferredFps:(NSInteger)fps
;

// fps <= 0 では setNeedsRedraw がセットされた時のみ描画するようにMTKViewを調整する.
- (instancetype _Nonnull)initWithChart:(MetalChart * _Nonnull)chart
								engine:(FMEngine * _Nullable)engine
								  view:(MetalView * _Nullable)view
						  preferredFps:(NSInteger)fps
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

- (FMDimensionalProjection * _Nullable)dimensionWithId:(NSInteger)dimensionId;

- (FMDimensionalProjection * _Nonnull)dimensionWithId:(NSInteger)dimensionId
								   confBlock:(DimensionConfigureBlock _Nonnull)block
;

// もしもidに対応するFMDimensionalProjectionがなければ、作成してblockを呼び出す. 
// 逆にすでに作成済みの場合はそれを使い、blockは呼ばれない.
// blockの戻り値でNonnullを返した場合は登録され、connectSpace:メソッドで自動的に使用される.
- (FMProjectionCartesian2D * _Nonnull)spaceWithDimensionIds:(NSArray<NSNumber*> * _Nonnull)ids
										 configureBlock:(DimensionConfigureBlock _Nullable)block
;

- (FMProjectionUpdater * _Nullable)updaterWithDimensionId:(NSInteger)dimensionId;

- (id<FMInteraction> _Nullable)connectSpace:(NSArray<FMProjectionCartesian2D*>* _Nonnull)space
							  toInterpreter:(FMGestureInterpreter * _Nonnull)interpreter
;

- (FMExclusiveAxis * _Nullable)addAxisToDimensionWithId:(NSInteger)dimensionId
								   belowSeries:(BOOL)below
								  configurator:(id<FMAxisConfigurator> _Nonnull)configurator
										 label:(FMAxisLabelDelegateBlock _Nullable)block
;

- (FMExclusiveAxis * _Nullable)addAxisToDimensionWithId:(NSInteger)dimensionId
								   belowSeries:(BOOL)below
								  configurator:(id<FMAxisConfigurator> _Nonnull)configurator
								labelFrameSize:(CGSize)size
							  labelBufferCount:(NSUInteger)count
										 label:(FMAxisLabelDelegateBlock _Nullable)block
;

// 上記２つのメソッドにはAxisLabelへアクセスする手段がない・・・ので、検索して返す必要がある.
- (NSArray<FMAxisLabel *> * _Nullable)axisLabelsToAxis:(id<FMAxis> _Nonnull)axis;

- (FMPlotArea * _Nonnull)addPlotAreaWithColor:(UIColor * _Nonnull)color;

- (FMGestureInterpreter * _Nonnull)addInterpreterToPanRecognizer:(FMPanGestureRecognizer *_Nullable)pan
												 pinchRecognizer:(UIPinchGestureRecognizer * _Nullable)pinch
												stateRestriction:(id<FMInterpreterStateRestriction> _Nullable)restriction
;

- (FMGridLine * _Nullable)addGridLineToDimensionWithId:(NSInteger)dimensionId
										   belowSeries:(BOOL)below
												anchor:(CGFloat)anchorValue
											  interval:(CGFloat)interval
;

// 以下のFMRenderable系の追加メソッドは適合するLineSeriesなどを返さずprimitiveを返しているが、
// これはLineSeriesなどはほとんど抽象化されラッパーとして機能しており、これを返すと細かいコントロールができないため.
// 各々適切に処理されてるので気にする必要はない.

- (FMOrderedPolyLinePrimitive * _Nonnull)addLineToSpace:(FMProjectionCartesian2D *_Nonnull)space
                                                 series:(FMOrderedSeries * _Nonnull)series
;

- (FMUniformPointAttributes* _Nonnull)setPointToLine:(FMLinePrimitive* _Nonnull)line
;

- (FMOrderedBarPrimitive * _Nonnull)addBarToSpace:(FMProjectionCartesian2D *_Nonnull)space
										   series:(FMOrderedSeries * _Nonnull)series
;

- (FMOrderedAttributedBarPrimitive * _Nonnull)addAttributedBarToSpace:(FMProjectionCartesian2D *_Nonnull)space
															   series:(FMOrderedAttributedSeries * _Nonnull)series
														 attrCapacity:(NSUInteger)capacity
;

- (FMOrderedPointPrimitive * _Nonnull)addPointToSpace:(FMProjectionCartesian2D *_Nonnull)space
											   series:(FMOrderedAttributedSeries * _Nonnull)series
;

- (FMOrderedAttributedPointPrimitive * _Nonnull)addAttributedPointToSpace:(FMProjectionCartesian2D * _Nonnull)space
                                                                   series:(FMOrderedAttributedSeries * _Nonnull)series
													   attributesCapacity:(NSUInteger)capacity
;

- (void)removeRenderable:(id<FMRenderable> _Nonnull)renderable;

- (FMBlockRenderable * _Nonnull)addBlockRenderable:(FMRenderBlock _Nonnull)block;

- (FMOrderedSeries * _Nonnull)createSeries:(NSUInteger)capacity
;

- (FMOrderedAttributedSeries * _Nonnull)createAttributedSeries:(NSUInteger)capacity
;


- (FMProjectionPolar * _Nonnull)addPolarSpace;
;

- (FMPieDoughnutSeries * _Nonnull)addPieSeriesToSpace:(FMProjectionPolar * _Nonnull)space
											 capacity:(NSUInteger)capacity
;

@end



