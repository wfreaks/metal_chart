//
//  FMRenderables.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/11.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MetalChart.h"

@class Engine;
@class LinePrimitive;
@class BarPrimitive;
@class PointPrimitive;
@class UniformLineAttributes;
@class UniformBarAttributes;
@class UniformPointAttributes;
@class UniformPlotRectAttributes;
@class FMPlotArea;

@protocol Series;

@protocol FMPlotAreaClient<FMDepthClient>

- (CGFloat)allocateRangeInPlotArea:(FMPlotArea *_Nonnull)area
                          minValue:(CGFloat)min
;

@end

@interface FMLineSeries : NSObject<FMRenderable, FMPlotAreaClient>

@property (readonly, nonatomic) LinePrimitive * _Nonnull line;
@property (readonly, nonatomic) UniformLineAttributes * _Nonnull attributes;
@property (readonly, nonatomic) id<Series> _Nullable series;

- (instancetype _Nonnull)initWithLine:(LinePrimitive * _Nonnull)line
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

+ (instancetype _Nonnull)orderedSeriesWithCapacity:(NSUInteger)capacity
											engine:(Engine * _Nonnull)engine
;

@end


@interface FMBarSeries : NSObject<FMRenderable, FMPlotAreaClient>

@property (readonly, nonatomic) BarPrimitive * _Nonnull bar;
@property (readonly, nonatomic) UniformBarAttributes * _Nonnull attributes;
@property (readonly, nonatomic) id<Series> _Nullable series;

- (instancetype _Nonnull)initWithBar:(BarPrimitive * _Nonnull)bar
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

+ (instancetype _Nonnull)orderedSeriesWithCapacity:(NSUInteger)capacity
											engine:(Engine * _Nonnull)engine
;

@end


@interface FMPointSeries : NSObject<FMRenderable>

@property (readonly, nonatomic) PointPrimitive * _Nonnull point;
@property (readonly, nonatomic) UniformPointAttributes * _Nonnull attributes;
@property (readonly, nonatomic) id<Series> _Nullable series;

- (instancetype _Nonnull)initWithPoint:(PointPrimitive * _Nonnull)point
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

+ (instancetype _Nonnull)orderedSeriesWithCapacity:(NSUInteger)capacity
											engine:(Engine * _Nonnull)engine
;

@end


@class PlotRect;

@interface FMPlotArea : NSObject<FMAttachment, FMDepthClient>

@property (readonly, nonatomic) UniformProjection * _Nonnull projection;
@property (readonly, nonatomic) PlotRect * _Nonnull rect;
@property (readonly, nonatomic) UniformPlotRectAttributes * _Nonnull attributes;

- (instancetype _Nonnull)initWithPlotRect:(PlotRect * _Nonnull)rect
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

+ (instancetype _Nonnull)rectWithEngine:(Engine *_Nonnull)engine;

@end
