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
@class Axis;

@interface MCAxis : NSObject<MCPreRenderable>

@property (readonly, nonatomic) MCSpatialProjection * _Nonnull		projection;
@property (readonly, nonatomic) NSInteger							dimensionId;

@property (readonly, nonatomic) Axis * _Nonnull                     axis;

- (_Nonnull instancetype)initWithEngine:(LineEngine * _Nonnull)engine
							 Projection:(MCSpatialProjection * _Nonnull)projection
							  dimension:(NSInteger)dimensionId
;

- (void)setMinorTickCountPerMajor:(NSUInteger)count;

@end

