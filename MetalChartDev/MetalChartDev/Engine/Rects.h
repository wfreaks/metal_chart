//
//  Rects.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/26.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Protocols.h"

@class Engine;
@class UniformProjection;
@class UniformPlotRect;
@class UniformBar;
@class OrderedSeries;

@protocol MTLRenderCommandEncoder;
@protocol Series;

@interface PlotRect : NSObject

@property (readonly, nonatomic) Engine * _Nonnull engine;
@property (readonly, nonatomic) UniformPlotRect * _Nonnull attributes;

- (instancetype _Nonnull)initWithEngine:(Engine * _Nonnull)engine;

- (void)encodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
        projection:(UniformProjection * _Nonnull)projection
;

@end


@interface BarPrimitive : NSObject<Primitive>

@property (readonly, nonatomic) Engine * _Nonnull engine;
@property (readonly, nonatomic) UniformBar * _Nonnull attributes;

- (id<Series> _Nullable)series;

@end

@interface OrderedBarPrimitive : BarPrimitive

@property (strong, nonatomic) OrderedSeries * _Nullable series;

- (instancetype _Nonnull)initWithEngine:(Engine * _Nonnull)engine
                                          series:(OrderedSeries * _Nullable)series
									  attributes:(UniformBar * _Nullable)attributes
;

@end
