//
//  Points.h
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/08/27.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Engine;
@class UniformProjection;
@class UniformPlotRect;
@class UniformPoint;
@class OrderedSeries;

@protocol MTLRenderCommandEncoder;
@protocol Series;

@interface PointPrimitive : NSObject

@property (readonly, nonatomic) Engine * _Nonnull engine;
@property (readonly, nonatomic) UniformPoint * _Nonnull point;
@property (readonly, nonatomic) id<Series> _Nonnull series;

- (void)encodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
        projection:(UniformProjection * _Nonnull)projection
;

@end

@interface OrderedPoint : PointPrimitive

@property (readonly, nonatomic) OrderedSeries * _Nonnull orderedSeries;

- (instancetype _Null_unspecified)initWithEngine:(Engine * _Nonnull)engine
                                          series:(OrderedSeries * _Nonnull)series;

@end

