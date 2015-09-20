//
//  MCRenderables.h
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
@class UniformPoint;

@interface MCLineSeries : NSObject<MCRenderable, MCDepthClient>

@property (readonly, nonatomic) LinePrimitive * _Nonnull line;

- (instancetype _Nonnull)initWithLine:(LinePrimitive * _Nonnull)line
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

+ (instancetype _Nonnull)orderedSeriesWithCapacity:(NSUInteger)capacity
											engine:(Engine * _Nonnull)engine
;

@end


@interface MCBarSeries : NSObject<MCRenderable>

@property (readonly, nonatomic) BarPrimitive * _Nonnull bar;

- (instancetype _Nonnull)initWithBar:(BarPrimitive * _Nonnull)bar
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

+ (instancetype _Nonnull)orderedSeriesWithCapacity:(NSUInteger)capacity
											engine:(Engine * _Nonnull)engine
;

@end


@interface MCPointSeries : NSObject<MCRenderable>

@property (readonly, nonatomic) PointPrimitive * _Nonnull point;

- (instancetype _Nonnull)initWithPoint:(PointPrimitive * _Nonnull)point
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

+ (instancetype _Nonnull)orderedSeriesWithCapacity:(NSUInteger)capacity
											engine:(Engine * _Nonnull)engine
;

@end


@class PlotRect;

@interface MCPlotArea : NSObject<MCAttachment>

@property (readonly, nonatomic) UniformProjection * _Nonnull projection;
@property (readonly, nonatomic) PlotRect * _Nonnull rect;

- (instancetype _Nonnull)initWithPlotRect:(PlotRect * _Nonnull)rect
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

+ (instancetype _Nonnull)rectWithEngine:(Engine *_Nonnull)engine;

@end
