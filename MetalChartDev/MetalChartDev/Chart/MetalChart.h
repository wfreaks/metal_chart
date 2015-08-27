//
//  MetalChart.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/09.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>
#import "Lines_common.h"

/*
 * このヘッダファイル内で宣言されたクラスは代替の利かないコアなコンポーネントの「全て」である.
 * その目的と興味はプロットエリアにおける座標変換のみに絞られている.
 * 軸・メモリ・レンジの制御・UI操作フィードバックなどはデフォルト実装を提供しているが、すべて独自定義クラスで代替可能.
 * 描画エンジンもMCRenderableを通して利用しているため、これらも独自定義可能である.
 * もちろんコード量と煩雑さはそこそこなのでオススメはできない.
 * (ただしUniformProjectionクラスだけは座標変換の仕組みに組み込まれているため、代替不可能.
 *  細かいハンドリングはMCRenderableが担当するためプロトコル化する事はできない)
 */

@class UniformProjection;
@class MetalChart;


/*
 * Renderable/AttachmentがDepthTestを必要とする場合、このプロトコルを実装する. 
 * 複数のドローコールが発行される関係上、Depthバッファの値の取りうる範囲（領域ではない）のうち、
 * どの範囲をどれが使用するかを把握していないと描画上の不整合を起こすため. 強制力は無い.
 * clientが使用可能な値は, 戻り値 R を用いて (minDepth <= v < minDepth + R) を満たすvである.
 * 負値は0として解釈される. このメソッドは描画オブジェクト配列に変更が加えられた時にコールされる.
 *
 * MetalChartの想定は、MTKView の clearDepthの値が0となっている事, depthが浮動小数点である事である.
 * また, 少なくともデフォルト実装では depthTestはMTLCompareFunctionGreaterを使う.
 *
 * また、当然ではあるがハンドリングされるのは
 * [MetalChart (add/remove)(Series/PreRenderable/PostRenderable):]
 * の引数に渡されたオブジェクトだけである.
 */
@protocol MCDepthClient <NSObject>

- (CGFloat)requestDepthRangeFrom:(CGFloat)min;

@end



@protocol MCRenderable <NSObject>

- (void)encodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
		projection:(UniformProjection * _Nonnull)projection
;

@end



@protocol MCAttachment <NSObject>

- (void)encodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
             chart:(MetalChart * _Nonnull)chart
              view:(MTKView * _Nonnull)view
;

@end


@protocol MCCommandBufferHook <NSObject>

- (void)chart:(MetalChart * _Nonnull)chart willStartEncodingToBuffer:(id<MTLCommandBuffer> _Nonnull)buffer;
- (void)chart:(MetalChart * _Nonnull)chart willCommitBuffer:(id<MTLCommandBuffer> _Nonnull)buffer;

@end


@interface MCDimensionalProjection : NSObject

@property (readonly, nonatomic) NSInteger dimensionId;
@property (assign  , nonatomic) CGFloat     min;
@property (assign  , nonatomic) CGFloat     max;
@property (copy    , nonatomic) void (^ _Nullable willUpdate)(CGFloat * _Nullable newMin, CGFloat * _Nullable newMax);

- (instancetype _Null_unspecified)initWithDimensionId:(NSInteger)dimId
											 minValue:(CGFloat)min
											 maxValue:(CGFloat)max
;

- (void)setMin:(CGFloat)min max:(CGFloat)max;

- (CGFloat)length;

@end


@interface MCSpatialProjection : NSObject

@property (readonly, nonatomic) NSArray<MCDimensionalProjection *> * _Nonnull dimensions;
@property (readonly, nonatomic) UniformProjection * _Nonnull projection;

- (instancetype _Null_unspecified)initWithDimensions:(NSArray<MCDimensionalProjection *> * _Nonnull)dimensions;

- (NSUInteger)rank;

- (void)writeToBuffer;

- (void)configure:(MTKView * _Nonnull)view padding:(RectPadding)padding;

- (MCDimensionalProjection * _Nullable)dimensionWithId:(NSInteger)dimensionId;

@end


@interface MetalChart : NSObject<MTKViewDelegate>

@property (copy   , nonatomic) void (^ _Nullable willDraw)(MetalChart * _Nonnull);
@property (copy   , nonatomic) void (^ _Nullable didDraw)(MetalChart * _Nonnull);
@property (strong , nonatomic) id<MCCommandBufferHook> _Nullable bufferHook;
@property (assign , nonatomic) RectPadding padding;

- (instancetype _Null_unspecified)init;

- (void)addSeries:(id<MCRenderable> _Nonnull)series
	   projection:(MCSpatialProjection * _Nonnull)projection
;

- (void)removeSeries:(id<MCRenderable> _Nonnull)series;

- (void)addPreRenderable:(id<MCAttachment> _Nonnull)object;
- (void)removePreRenderable:(id<MCAttachment> _Nonnull)object;

- (void)addPostRenderable:(id<MCAttachment> _Nonnull)object;
- (void)removePostRenderable:(id<MCAttachment> _Nonnull)object;

- (NSArray<id<MCRenderable>> * _Nonnull)series;

- (NSArray<MCSpatialProjection *> * _Nonnull)projections;

@end
