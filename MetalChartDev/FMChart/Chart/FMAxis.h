//
//  FMAxis.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/11.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MetalChart.h"

@class FMEngine;
@class FMUniformLineAttributes;
@class FMAxisPrimitive;
@class FMUniformAxisConfiguration;
@class FMAxis;

typedef void (^FMAxisConfiguratorBlock)(FMUniformAxisConfiguration *_Nonnull axis,
										FMDimensionalProjection *_Nonnull dimension,
										FMDimensionalProjection *_Nonnull orthogonal,
                                        BOOL isFirst
                                        );

@protocol FMAxisConfigurator<NSObject>

- (void)configureUniform:(FMUniformAxisConfiguration * _Nonnull)uniform
		   withDimension:(FMDimensionalProjection * _Nonnull)dimension
			  orthogonal:(FMDimensionalProjection * _Nonnull)orthogonal
;

@end


@protocol FMAxisDecoration<NSObject>

- (void)encodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
			  axis:(FMAxis * _Nonnull)axis
		projection:(FMUniformProjectionCartesian2D * _Nonnull)projection
;

@end


@interface FMAxis : NSObject<FMAttachment>

@property (readonly, nonatomic) FMProjectionCartesian2D *	_Nonnull  projection;
@property (readonly, nonatomic) FMDimensionalProjection *	_Nonnull  dimension;

@property (readonly, nonatomic) FMAxisPrimitive *			_Nonnull  axis;
@property (readonly, nonatomic) id<FMAxisConfigurator>		_Nonnull  conf;
@property (strong  , nonatomic) id<FMAxisDecoration>		_Nullable decoration;

- (_Nonnull instancetype)initWithEngine:(FMEngine * _Nonnull)engine
							 Projection:(FMProjectionCartesian2D * _Nonnull)projection
							  dimension:(NSInteger)dimensionId
						  configuration:(id<FMAxisConfigurator> _Nonnull)conf
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;


- (void)setMinorTickCountPerMajor:(NSUInteger)count;

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

@end





