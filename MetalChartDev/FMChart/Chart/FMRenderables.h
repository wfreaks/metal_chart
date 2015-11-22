//
//  FMRenderables.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/11.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MetalChart.h"
#import "FMProjections.h"

@class FMEngine;
@class FMLinePrimitive;
@class FMBarPrimitive;
@class FMOrderedAttributedBarPrimitive;
@class FMPointPrimitive;
@class FMUniformLineAttributes;
@class FMUniformBarConfiguration;
@class FMUniformRectAttributesArray;
@class FMUniformPointAttributes;
@class FMUniformPlotRectAttributes;
@class FMUniformGridAttributes;
@class FMPlotArea;

@protocol FMSeries;


typedef void (^FMRenderBlock)(id<MTLRenderCommandEncoder>_Nonnull encoder, MetalChart *_Nonnull chart);

@interface FMBlockRenderable : NSObject<FMRenderable>

@property (nonatomic, copy, readonly) _Nonnull FMRenderBlock block;

- (instancetype _Nonnull)init
UNAVAILABLE_ATTRIBUTE;

- (instancetype _Nonnull)initWithBlock:(FMRenderBlock _Nonnull)block
NS_DESIGNATED_INITIALIZER;

@end


@protocol FMPlotAreaClient<FMDepthClient>

- (CGFloat)allocateRangeInPlotArea:(FMPlotArea *_Nonnull)area
                          minValue:(CGFloat)min
;

@end

@interface FMLineSeries : NSObject<FMRenderable, FMPlotAreaClient>

@property (readonly, nonatomic) FMLinePrimitive * _Nonnull line;
@property (readonly, nonatomic) FMUniformLineAttributes * _Nonnull attributes;
@property (readonly, nonatomic) id<FMSeries> _Nullable series;
@property (nonatomic)			FMProjectionCartesian2D * _Nullable projection;

- (instancetype _Nonnull)initWithLine:(FMLinePrimitive * _Nonnull)line
						   projection:(FMProjectionCartesian2D * _Nullable)projection
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

+ (instancetype _Nonnull)orderedSeriesWithCapacity:(NSUInteger)capacity
											engine:(FMEngine * _Nonnull)engine
										projection:(FMProjectionCartesian2D * _Nonnull)projection
;

@end


@interface FMBarSeries : NSObject<FMRenderable, FMPlotAreaClient>

@property (readonly, nonatomic) FMBarPrimitive * _Nonnull bar;
@property (readonly, nonatomic) FMUniformBarConfiguration * _Nonnull conf;
@property (readonly, nonatomic) id<FMSeries> _Nullable series;
@property (nonatomic)			FMProjectionCartesian2D * _Nullable projection;

- (instancetype _Nonnull)initWithBar:(FMBarPrimitive * _Nonnull)bar
						  projection:(FMProjectionCartesian2D * _Nullable)projection
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

+ (instancetype _Nonnull)orderedSeriesWithCapacity:(NSUInteger)capacity
											engine:(FMEngine * _Nonnull)engine
										projection:(FMProjectionCartesian2D * _Nonnull)projection
;

@end

@interface FMAttributedBarSeries : FMBarSeries

@property (readonly, nonatomic) FMOrderedAttributedBarPrimitive * _Nonnull attributedBar;
@property (readonly, nonatomic) FMUniformRectAttributesArray * _Nonnull attrs;

- (instancetype _Nonnull)initWithBar:(FMBarPrimitive * _Nonnull)bar
						  projection:(FMProjectionCartesian2D * _Nullable)projection
UNAVAILABLE_ATTRIBUTE;

- (instancetype _Nonnull)initWithAttributedBar:(FMOrderedAttributedBarPrimitive * _Nonnull)bar
									projection:(FMProjectionCartesian2D * _Nullable)projection
;

+ (instancetype _Nonnull)orderedSeriesWithCapacity:(NSUInteger)capacity
											engine:(FMEngine * _Nonnull)engine
										projection:(FMProjectionCartesian2D * _Nonnull)projection
UNAVAILABLE_ATTRIBUTE;

+ (instancetype _Nonnull)orderedSeriesWithCapacity:(NSUInteger)seriesCapacity
								attributesCapacity:(NSUInteger)attrCapacity
											engine:(FMEngine * _Nonnull)engine
										projection:(FMProjectionCartesian2D * _Nonnull)projection
;

@end


@interface FMPointSeries : NSObject<FMRenderable>

@property (readonly, nonatomic) FMPointPrimitive * _Nonnull point;
@property (readonly, nonatomic) FMUniformPointAttributes * _Nonnull attributes;
@property (readonly, nonatomic) id<FMSeries> _Nullable series;
@property (nonatomic)			FMProjectionCartesian2D * _Nullable projection;

- (instancetype _Nonnull)initWithPoint:(FMPointPrimitive * _Nonnull)point
							projection:(FMProjectionCartesian2D * _Nullable)projection
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

+ (instancetype _Nonnull)orderedSeriesWithCapacity:(NSUInteger)capacity
											engine:(FMEngine * _Nonnull)engine
										projection:(FMProjectionCartesian2D * _Nonnull)projection
;

@end


@class FMPlotRectPrimitive;

@interface FMPlotArea : NSObject<FMAttachment, FMDepthClient>

@property (readonly, nonatomic) FMUniformProjectionCartesian2D * _Nonnull projection;
@property (readonly, nonatomic) FMPlotRectPrimitive * _Nonnull rect;
@property (readonly, nonatomic) FMUniformPlotRectAttributes * _Nonnull attributes;

- (instancetype _Nonnull)initWithPlotRect:(FMPlotRectPrimitive * _Nonnull)rect
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

+ (instancetype _Nonnull)rectWithEngine:(FMEngine *_Nonnull)engine;

@end

@class FMGridLinePrimitive;
@class FMAxis;

@interface FMGridLine : NSObject<FMAttachment, FMPlotAreaClient>

@property (readonly, nonatomic) FMUniformGridAttributes * _Nonnull attributes;
@property (readonly, nonatomic) FMGridLinePrimitive		* _Nonnull gridLine;
@property (readonly, nonatomic) FMProjectionCartesian2D * _Nonnull projection;
@property (nonatomic)			FMAxis					* _Nullable axis;

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
