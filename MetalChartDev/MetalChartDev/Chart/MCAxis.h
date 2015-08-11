//
//  MCAxis.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/11.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MetalChart.h"

@class LineEngine;
@class UniformLineAttributes;

@interface MCAxis : NSObject<MCPreRenderable>

@property (readonly, nonatomic) MCSpatialProjection * _Nonnull		projection;
@property (readonly, nonatomic) NSInteger							dimensionId;
@property (readonly, nonatomic) UniformLineAttributes * _Nonnull	attributes;

@property (assign  , nonatomic) CGFloat								anchorPoint;

// anchorPointの解釈を決めるフラグ. YESならばprojectionの可視領域の範囲で位置が変わり、NOならばプロット領域に対して固定となる.
// この場合は-1がBottom/Left, +1がTop/Rightとなる
@property (assign  , nonatomic) BOOL      anchorToProjection; 

- (_Nonnull instancetype)initWithEngine:(LineEngine * _Nonnull)engine
							 Projection:(MCSpatialProjection * _Nonnull)projection
							  dimension:(NSInteger)dimensionId
;

@end
