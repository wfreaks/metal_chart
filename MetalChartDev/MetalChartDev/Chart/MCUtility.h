//
//  MCUtility.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/09/20.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>

// モジュラーな設計を心がけると、使いかたの幅が広がると同時に、クラス階層と関係性の理解を強制されるが、
// アプリケーションコードはある意味では迂遠なものになる（実際にはそれが正しい姿だが、往々にして典型的なコードを要求される）。
// そのあたりの不満を解消するためのルーチン集がここに集められる.
// また、クラス関係を理解するためのエントリポイントとしての意味もある.

@class MetalChart;
@class MCDimensionalProjection;
@class MCSpatialProjection;
@class MCProjectionUpdater;
@class MCAxis;
@class MCAxisLabel;
@class MCGestureInterpreter;
@class Engine;

@protocol MCInteraction;

@interface MCUtility : NSObject

@end

typedef MCProjectionUpdater * _Nullable (^DimensionConfigureBlock)(NSInteger dimensionID);

// Chartに対しての設定を簡潔にするためのオブジェクト.
// ただし、効率性や柔軟性を重視するなら、このクラスを使わずに手で設定することをお勧めする.
// (初期設定時の負荷など描画に比べれば微々たるものなので、効率が問題になることはまずないとは思う)

@interface MCConfigurator : NSObject

@property (readonly, nonatomic) NSArray<MCDimensionalProjection*> * _Nonnull dimensions;
@property (readonly, nonatomic) NSArray<MCProjectionUpdater*> * _Nonnull updaters;
@property (readonly, nonatomic) NSArray<MCSpatialProjection*> * _Nonnull space;
@property (readonly, nonatomic) MetalChart * _Nonnull chart;
@property (readonly, nonatomic) Engine * _Nonnull engine;

- (instancetype _Nonnull)initWithChart:(MetalChart * _Nonnull)chart
								engine:(Engine * _Nullable)engine
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;


- (MCSpatialProjection * _Nonnull)spaceWithDimensionIds:(NSArray<NSNumber*> * _Nonnull)ids
										 configureBlock:(DimensionConfigureBlock _Nullable)block
;

- (MCProjectionUpdater * _Nullable)updaterWithDimensionId:(NSInteger)dimensionId;

- (id<MCInteraction> _Nullable)connectSpace:(NSArray<MCSpatialProjection*>* _Nonnull)space
							  toInterpreter:(MCGestureInterpreter * _Nonnull)interpreter
;

@end
