//
//  FMRenderables.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/11.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MetalChart.h"
#import "FMProjections.h"


typedef void (^FMRenderBlock)(id<MTLRenderCommandEncoder>_Nonnull encoder, MetalChart *_Nonnull chart);

/**
 * A simple block-wrapper class for FMRenderable.
 * (this class is almost useless imo...)
 */
@interface FMBlockRenderable : NSObject<FMRenderable>

@property (nonatomic, copy, readonly) _Nonnull FMRenderBlock block;

- (instancetype _Nonnull)init
UNAVAILABLE_ATTRIBUTE;

- (instancetype _Nonnull)initWithBlock:(FMRenderBlock _Nonnull)block
NS_DESIGNATED_INITIALIZER;

@end


/**
 * FMPlotAreaClient defines methods that attachements and renderables which requires to be masked by plot area (and its corner) must implement.
 * FMPlotArea handles values returned by its clients, and then write sum of them to depth buffer.
 * Depth value range that each client can use is [min, min+r) where r represents return value.
 * if this method was called (i.e. an FMPlotArea instance is below clients), then they can ignore (return 0) methods defined in FMDepthClient protocol.
 */

@protocol FMPlotAreaClient<FMDepthClient>

- (CGFloat)allocateRangeInPlotArea:(FMPlotArea *_Nonnull)area
						  minValue:(CGFloat)min
;

@end


/**
 * FMLineSeries represents renderable data series using polyline.
 * If the line is attributed (FMAttributedLinePrimitive), then attribute index of last data will be ignored.
 * (Attributes of a line segment between point 1 and 2 will be that of index specified by point 1).
 *
 * See Engine/Line/LineBuffers.h and Engine/Line/Lines.h for the list of properties.
 */
@interface FMLineSeries : NSObject<FMRenderable, FMPlotAreaClient>

@property (readonly, nonatomic) FMLinePrimitive * _Nonnull line;
@property (readonly, nonatomic) FMUniformLineConf * _Nonnull conf;
@property (readonly, nonatomic) id<FMSeries> _Nullable series;
@property (nonatomic)			FMProjectionCartesian2D * _Nullable projection;

- (instancetype _Nonnull)initWithLine:(FMLinePrimitive * _Nonnull)line
						   projection:(FMProjectionCartesian2D * _Nullable)projection
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

/**
 * creates unattributed line series with vertex buffer(default size specified by capacity) with given projection.
 */
+ (instancetype _Nonnull)orderedSeriesWithCapacity:(NSUInteger)capacity
											engine:(FMEngine * _Nonnull)engine
										projection:(FMProjectionCartesian2D * _Nonnull)projection
;

@end


/**
 * FMBarSeries represents renderable data series using horizontal/vertical bars (orientation is configured using conf property).
 * You can set an FMAttributedBarPrimitive instance to bar property (on creation).
 *
 * See Engine/Rect/RectBuffers.h and Engine/Rect/Rects.h for the list of properties.
 */
 
@interface FMBarSeries : NSObject<FMRenderable, FMPlotAreaClient>

@property (readonly, nonatomic) FMBarPrimitive * _Nonnull bar;
@property (readonly, nonatomic) FMUniformBarConfiguration * _Nonnull conf;
@property (readonly, nonatomic) id<FMSeries> _Nullable series;
@property (nonatomic)			FMProjectionCartesian2D * _Nullable projection;

- (instancetype _Nonnull)initWithBar:(FMBarPrimitive * _Nonnull)bar
						  projection:(FMProjectionCartesian2D * _Nullable)projection
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

@end


/**
 * FMPointSeries represents renderable data series using points.
 * You can use an FMAttributedPointPrimitive instance.
 *
 * See Engine/Point/PointBuffers.h and Engine/Point/Points.h for the list of properties.
 */

@interface FMPointSeries : NSObject<FMRenderable>

@property (readonly, nonatomic) FMPointPrimitive * _Nonnull point;
@property (readonly, nonatomic) id<FMSeries> _Nullable series;
@property (nonatomic)			FMProjectionCartesian2D * _Nullable projection;

- (instancetype _Nonnull)initWithPoint:(FMPointPrimitive * _Nonnull)point
							projection:(FMProjectionCartesian2D * _Nullable)projection
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

@end


/**
 * FMPlotArea represents an attachment that fills plot area (view - padding) using colors and radius for each corner.
 * you can configure those using attributes property.
 *
 * See Engine/Rects/Rects.h for more details.
 */

@interface FMPlotArea : NSObject<FMAttachment, FMDepthClient>

@property (readonly, nonatomic) FMUniformProjectionCartesian2D * _Nonnull projection;
@property (readonly, nonatomic) FMPlotRectPrimitive * _Nonnull rect;
@property (readonly, nonatomic) FMUniformPlotRectAttributes * _Nonnull attributes;

- (instancetype _Nonnull)initWithPlotRect:(FMPlotRectPrimitive * _Nonnull)rect
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

+ (instancetype _Nonnull)rectWithEngine:(FMEngine *_Nonnull)engine;

@end


/**
 * FMGridLine is an attachment that draw (dashed) lines which is perpendicular to an axis from an edge of underlying plot area to the other.
 * (you can use a grid line without an axis, but you have to configure it by yourself in that case.)
 *
 * See Engine/Lines/LineBuffers.h and Engine/Lines/Lines.h for more details.
 */

@interface FMGridLine : NSObject<FMDependentAttachment, FMPlotAreaClient>

@property (readonly, nonatomic) FMUniformGridConfiguration * _Nonnull configuration;
@property (readonly, nonatomic) FMUniformGridAttributes * _Nonnull attributes;
@property (readonly, nonatomic) FMGridLinePrimitive		* _Nonnull gridLine;
@property (readonly, nonatomic) FMProjectionCartesian2D * _Nonnull projection;

/**
 * set an axis you want to synchronize configuration (anchor and interval) with it.
 * make sure that an axis and a grid line share a same instance of FMProjectionCartesian2D and a dimensionId.
 */
@property (nonatomic)			id<FMAxis>				  _Nullable axis;

/**
 * if axis property is not nil, then sticksToMinorTicks property controls interval of each gridline (that of major ticks or minor ticks).
 */
@property (nonatomic)			BOOL								sticksToMinorTicks;

- (_Nonnull instancetype)initWithGridLine:(FMGridLinePrimitive * _Nonnull)gridLine
							   Projection:(FMProjectionCartesian2D * _Nonnull)projection
								dimension:(NSInteger)dimensionId
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

+ (instancetype _Nonnull)gridLineWithEngine:(FMEngine * _Nonnull)engine
								 projection:(FMProjectionCartesian2D * _Nonnull)projection
								  dimension:(NSInteger)dimensionId;
;

@end
