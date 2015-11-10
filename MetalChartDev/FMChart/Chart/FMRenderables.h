//
//  FMRenderables.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/11.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MetalChart.h"

@class FMEngine;
@class LinePrimitive;
@class BarPrimitive;
@class PointPrimitive;
@class UniformLineAttributes;
@class UniformBarAttributes;
@class UniformPointAttributes;
@class UniformPlotRectAttributes;
@class UniformGridAttributes;
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
@property (nonatomic)			FMProjectionCartesian2D * _Nullable projection;

- (instancetype _Nonnull)initWithLine:(LinePrimitive * _Nonnull)line
						   projection:(FMProjectionCartesian2D * _Nullable)projection
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

+ (instancetype _Nonnull)orderedSeriesWithCapacity:(NSUInteger)capacity
											engine:(FMEngine * _Nonnull)engine
										projection:(FMProjectionCartesian2D * _Nonnull)projection
;

@end


@interface FMBarSeries : NSObject<FMRenderable, FMPlotAreaClient>

@property (readonly, nonatomic) BarPrimitive * _Nonnull bar;
@property (readonly, nonatomic) UniformBarAttributes * _Nonnull attributes;
@property (readonly, nonatomic) id<Series> _Nullable series;
@property (nonatomic)			FMProjectionCartesian2D * _Nullable projection;

- (instancetype _Nonnull)initWithBar:(BarPrimitive * _Nonnull)bar
						  projection:(FMProjectionCartesian2D * _Nullable)projection
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

+ (instancetype _Nonnull)orderedSeriesWithCapacity:(NSUInteger)capacity
											engine:(FMEngine * _Nonnull)engine
										projection:(FMProjectionCartesian2D * _Nonnull)projection
;

@end


@interface FMPointSeries : NSObject<FMRenderable>

@property (readonly, nonatomic) PointPrimitive * _Nonnull point;
@property (readonly, nonatomic) UniformPointAttributes * _Nonnull attributes;
@property (readonly, nonatomic) id<Series> _Nullable series;
@property (nonatomic)			FMProjectionCartesian2D * _Nullable projection;

- (instancetype _Nonnull)initWithPoint:(PointPrimitive * _Nonnull)point
							projection:(FMProjectionCartesian2D * _Nullable)projection
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

+ (instancetype _Nonnull)orderedSeriesWithCapacity:(NSUInteger)capacity
											engine:(FMEngine * _Nonnull)engine
										projection:(FMProjectionCartesian2D * _Nonnull)projection
;

@end


@class PlotRect;

@interface FMPlotArea : NSObject<FMAttachment, FMDepthClient>

@property (readonly, nonatomic) UniformProjectionCartesian2D * _Nonnull projection;
@property (readonly, nonatomic) PlotRect * _Nonnull rect;
@property (readonly, nonatomic) UniformPlotRectAttributes * _Nonnull attributes;

- (instancetype _Nonnull)initWithPlotRect:(PlotRect * _Nonnull)rect
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

+ (instancetype _Nonnull)rectWithEngine:(FMEngine *_Nonnull)engine;

@end

@class GridLine;

@interface FMGridLine : NSObject<FMAttachment, FMPlotAreaClient>

@property (readonly, nonatomic) UniformGridAttributes * _Nonnull attributes;
@property (readonly, nonatomic) GridLine * _Nonnull gridLine;
@property (readonly, nonatomic) FMProjectionCartesian2D * _Nonnull projection;

- (_Nonnull instancetype)initWithGridLine:(GridLine * _Nonnull)gridLine
                               Projection:(FMProjectionCartesian2D * _Nonnull)projection
                                dimension:(NSInteger)dimensionId
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

+ (instancetype _Nonnull)gridLineWithEngine:(FMEngine * _Nonnull)engine
                                 projection:(FMProjectionCartesian2D * _Nonnull)projection
                                  dimension:(NSInteger)dimensionId;
;

@end
