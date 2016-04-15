//
//  MetalChart.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/09.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "chart_common.h"
#import "Engine_common.h"

MTLPixelFormat determineDepthPixelFormat();

/*
 * このヘッダファイル内で宣言されたクラスは代替の利かないコアなコンポーネントの「全て」である.
 * その目的と興味はプロットエリアにおける座標変換のみに絞られている.
 * 軸・メモリ・レンジの制御・UI操作フィードバックなどはデフォルト実装を提供しているが、すべて独自定義クラスで代替可能.
 * 描画エンジンもFMRenderableを通して利用しているため、これらも独自定義可能である.
 * もちろんコード量と煩雑さはそこそこなのでオススメはできない.
 */

@class MetalChart;


/*
 * Renderable/AttachmentがDepthTestを必要とする場合、このプロトコルを実装する. 
 * 複数のドローコールが発行される関係上、Depthバッファの値の取りうる範囲（領域ではない）のうち、
 * どの範囲をどれが使用するかを把握していないと描画上の不整合を起こすため. 強制力は無い.
 * clientが使用可能な値は, 戻り値 R を用いて (minDepth < v <= minDepth + |R|) を満たすvである.
 * Rの絶対値を取るのは、R < 0 の場合はclearDepthよりも小さい値をデプスバッファに書き込む事を意味し、
 * かつdepthテストでは負値を使えないようなので逆にclearDepthを上げる事で対処するためのものである.
 * ちなみに、この「掘り下げる」のはプロット領域を角丸にしつつ、そこでマスクをするなどの機能で使う.
 *
 * MetalChartの想定は、MTKView の clearDepthの値が0となっている事, depthが浮動小数点である事である.
 * また, 少なくともデフォルト実装では depthTestはMTLCompareFunctionGreaterを使う.
 *
 * また、当然ではあるがハンドリングされるのは
 * [MetalChart (add/remove)(Series/PreRenderable/PostRenderable):]
 * の引数に渡されたオブジェクトだけである.
 */
@protocol FMDepthClient <NSObject>

- (CGFloat)requestDepthRangeFrom:(CGFloat)min
						 objects:(NSArray * _Nonnull)objects;

@end

/*
 * FMRenderableは系列データ（プロットされる実際のデータ）が実装するべきプロトコル.
 * いわゆるaddSeriesでChartに追加するもの.
 * requiredは以下のenocdeWith:chart:だけだが、大抵は内部でProjectionへの参照が必要になる.
 * （要は画面上の点にマッピングできればそれで構わない、デフォルト実装はそういう思想にのっとっているというだけ.
 * 　ただそのマッピング情報は本当に他の系列と共有する必要がないのか、FMProjectionへのサポートなしで
 * 　問題ないかを検討はすべきである）
 * ちなみに系列データはデータであるべきで、正常な描画に軸などのAttachmentへの依存関係などを作るべきではない.
 */


@protocol FMRenderable<NSObject>

- (void)encodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
			 chart:(MetalChart * _Nonnull)chart
;

@end


/*
 * FMAttachmentは軸などの付加的な描画要素が実装するべきプロトコル.
 * ただし目盛りのラベルは軸に依存する場合など、あらかじめ依存しているAttachmentが準備を終わらせておかなければ
 * いけない状況が存在する. このような問題に対して、描画順に依存せずに対処すりために、描画とは別の
 * メソッドを要求する. また、この依存関係を順序として解決するためのoptionalメソッドも必要に応じて実装する.
 * 
 * こういった依存関係を解決するような処理は描画時にやるものではない.
 * もちろんそうすれば変更後の反映は即時行われるようになるが、addする前に正しく設定しないとか
 * 実行時に途中で変更するとかいう割と珍しいニーズは、専用の方法で満たしてもらう.
 * 具体的には[FMChat requestResolveAttachmentDependencies]を使用する事.
 */

@protocol FMAttachment <NSObject>

- (void)encodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
			 chart:(MetalChart * _Nonnull)chart
			  view:(MetalView * _Nonnull)view
;

@end

@protocol FMDependentAttachment <FMAttachment>

- (void)prepare:(MetalChart * _Nonnull)chart
		   view:(MetalView * _Nonnull)view
;

@optional
- (NSArray<id<FMDependentAttachment>> * _Nullable)dependencies
;

@end


@protocol FMCommandBufferHook <NSObject>

- (void)chart:(MetalChart * _Nonnull)chart willStartEncodingToBuffer:(id<MTLCommandBuffer> _Nonnull)buffer;
- (void)chart:(MetalChart * _Nonnull)chart willCommitBuffer:(id<MTLCommandBuffer> _Nonnull)buffer;

@end


@protocol FMProjection <NSObject>

- (void)writeToBuffer;

- (void)configure:(MetalView * _Nonnull)view padding:(RectPadding)padding;

@end


@interface MetalChart : NSObject<MetalViewDelegate>

@property (copy   , nonatomic) void (^ _Nullable willDraw)(MetalChart * _Nonnull);
@property (copy   , nonatomic) void (^ _Nullable didDraw)(MetalChart * _Nonnull);
@property (weak   , nonatomic) id<FMCommandBufferHook> _Nullable bufferHook;
@property (assign , nonatomic) RectPadding padding;
@property (readonly, nonatomic) CGFloat clearDepth;

// dictionaryとかのキーにするためのunique idプロパティ. 実体はただのアドレス文字列.
@property (readonly, nonatomic) NSString * _Nonnull key;

- (instancetype _Nonnull)init NS_DESIGNATED_INITIALIZER;

// 以下でArrayごと追加するメソッドは、単純にクライアントコードをシンプルにするためだけのものであって、
// 最適化などはしていないので注意.

// また、すでに追加されているものを再度追加しようとした場合、あるいは追加されていないものを除こうとした場合、
// そのメソッドは何もしない. 他の条件が不正な呼び出しもそれに準ずる.

- (void)addRenderable:(id<FMRenderable> _Nonnull)renderable;
- (void)addRenderableArray:(NSArray<id<FMRenderable>> *_Nonnull)renderables;
- (void)removeRenderable:(id<FMRenderable> _Nonnull)renderable;

- (void)addProjection:(id<FMProjection> _Nonnull)projection;
- (void)addProjections:(NSArray<id<FMProjection>> *_Nonnull)projections;
- (void)removeProjection:(id<FMProjection> _Nonnull)projection;

- (void)addPreRenderable:(id<FMAttachment> _Nonnull)object;
- (void)insertPreRenderable:(id<FMAttachment> _Nonnull)object atIndex:(NSUInteger)index;
- (void)addPreRenderables:(NSArray<id<FMAttachment>> * _Nonnull)array;
- (void)removePreRenderable:(id<FMAttachment> _Nonnull)object;

- (void)addPostRenderable:(id<FMAttachment> _Nonnull)object;
- (void)insertPostRenderable:(id<FMAttachment> _Nonnull)object atIndex:(NSUInteger)index;
- (void)addPostRenderables:(NSArray<id<FMAttachment>> * _Nonnull)array;
- (void)removePostRenderable:(id<FMAttachment> _Nonnull)object;

- (void)removeAll;

- (void)requestResolveAttachmentDependencies;

- (NSArray<id<FMRenderable>> * _Nonnull)renderables;

- (NSSet<id<FMProjection>> * _Nonnull)projectionSet;

@end



