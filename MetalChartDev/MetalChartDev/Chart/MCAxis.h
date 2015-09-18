//
//  MCAxis.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/11.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MetalChart.h"

@class Engine;
@class UniformLineAttributes;
@class Axis;
@class UniformAxisConfiguration;
@class MCAxis;

typedef void (^MCAxisConfiguratorBlock)(UniformAxisConfiguration *_Nonnull axis,
										MCDimensionalProjection *_Nonnull dimension,
										MCDimensionalProjection *_Nonnull orthogonal,
                                        BOOL isFirst
                                        );

@protocol MCAxisConfigurator<NSObject>

- (void)configureUniform:(UniformAxisConfiguration * _Nonnull)uniform
		   withDimension:(MCDimensionalProjection * _Nonnull)dimension
			  orthogonal:(MCDimensionalProjection * _Nonnull)orthogonal
;

@end


@protocol MCAxisDecoration<NSObject>

- (void)encodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
			  axis:(MCAxis * _Nonnull)axis
		projection:(UniformProjection * _Nonnull)projection
;

@end


@interface MCAxis : NSObject<MCAttachment>

@property (readonly, nonatomic) MCSpatialProjection *		_Nonnull  projection;
@property (readonly, nonatomic) MCDimensionalProjection *	_Nonnull  dimension;

@property (readonly, nonatomic) Axis *						_Nonnull  axis;
@property (readonly, nonatomic) id<MCAxisConfigurator>		_Nonnull  conf;
@property (strong  , nonatomic) id<MCAxisDecoration>		_Nullable decoration;

- (_Nonnull instancetype)initWithEngine:(Engine * _Nonnull)engine
							 Projection:(MCSpatialProjection * _Nonnull)projection
							  dimension:(NSInteger)dimensionId
						  configuration:(id<MCAxisConfigurator> _Nonnull)conf
;

- (void)setMinorTickCountPerMajor:(NSUInteger)count;

@end


// 全ての項目を自由に、かつ効率的にコントロールするためのクラス（だが宣言的ではない）
// 固定機能クラスも作ろうと思ったけど全部代用できるのでやめた.
@interface MCBlockAxisConfigurator : NSObject<MCAxisConfigurator>

- (instancetype _Nonnull)initWithBlock:(MCAxisConfiguratorBlock _Nonnull)block;

// 1度だけ与えられた値をそのままconfへ設定する.
// axisAnchorはデータ空間での位置なので、グラフを動かすと一緒に動いて場合によってはプロット領域の外に出る.
// もしも範囲外へ出たら端で留めたいというような特殊な事がやりたいならば、自分でブロックを書くべきだ.
// (そういう「宜しくやってくれる」部品を集めた時、)
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





