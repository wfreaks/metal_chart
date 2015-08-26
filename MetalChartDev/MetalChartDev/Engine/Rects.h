//
//  Rects.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/26.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Engine;
@class UniformProjection;
@class UniformPlotRect;
@class UniformBar;
@class OrderedSeries;

@protocol MTLRenderCommandEncoder;
@protocol Series;

@interface PlotRect : NSObject

@property (readonly, nonatomic) Engine * _Nonnull engine;
@property (readonly, nonatomic) UniformPlotRect * _Nonnull rect;

- (instancetype _Null_unspecified)initWithEngine:(Engine * _Nonnull)engine;

- (void)encodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
        projection:(UniformProjection * _Nonnull)projection
;

@end


@interface Bar : NSObject

@property (readonly, nonatomic) Engine * _Nonnull engine;
@property (readonly, nonatomic) UniformBar * _Nonnull bar;
@property (readonly, nonatomic) id<Series> _Nonnull series;

- (void)encodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
        projection:(UniformProjection * _Nonnull)projection
;

@end

@interface OrderedBar : Bar

@property (readonly, nonatomic) OrderedSeries * _Nonnull orderedSeries;

- (instancetype _Null_unspecified)initWithEngine:(Engine * _Nonnull)engine
                                          series:(OrderedSeries * _Nonnull)series;

@end
