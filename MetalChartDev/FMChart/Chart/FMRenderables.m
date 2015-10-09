//
//  FMRenderables.m
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/11.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "FMRenderables.h"
#import "DeviceResource.h"
#import "Engine.h"
#import "Buffers.h"
#import "Series.h"
#import "Lines.h"
#import "Rects.h"
#import "Points.h"
#import "LineBuffers.h"
#import "RectBuffers.h"

@interface FMLineSeries()

@end

@implementation FMLineSeries

- (instancetype)initWithLine:(LinePrimitive *)line
{
	self = [super init];
	if(self) {
		_line = line;
	}
	return self;
}

- (UniformLineAttributes *)attributes { return _line.attributes; }

- (id<Series>)series { return [_line series]; }

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
		projection:(UniformProjection *)projection
{
	[_line encodeWith:encoder projection:projection];
}

- (CGFloat)requestDepthRangeFrom:(CGFloat)min objects:(NSArray * _Nonnull)objects
{
    for(id obj in objects) {
        if([obj isKindOfClass:[FMPlotArea class]]) {
            return 0;
        }
    }
    [self.attributes setDepthValue:min+0.05];
    return 0.1;
}

- (CGFloat)allocateRangeInPlotArea:(FMPlotArea *)area minValue:(CGFloat)min
{
    [self.attributes setDepthValue:min+0.05];
    return 0.1;
}

+ (instancetype)orderedSeriesWithCapacity:(NSUInteger)capacity
								   engine:(Engine *)engine
{
	OrderedSeries *series = [[OrderedSeries alloc] initWithResource:engine.resource
													 vertexCapacity:capacity];
	OrderedPolyLinePrimitive *line = [[OrderedPolyLinePrimitive alloc] initWithEngine:engine
																		orderedSeries:series
																		   attributes:nil];
	return [[self alloc] initWithLine:line];
}

@end

@implementation FMBarSeries

- (instancetype)initWithBar:(BarPrimitive *)bar
{
    self = [super init];
    if(self) {
        _bar = bar;
    }
    return self;
}

- (CGFloat)requestDepthRangeFrom:(CGFloat)min objects:(NSArray * _Nonnull)objects
{
    for(id obj in objects) {
        if([obj isKindOfClass:[FMPlotArea class]]) {
            return 0;
        }
    }
    [self.attributes setDepthValue:min+0.05];
    return 0.1;
}

- (CGFloat)allocateRangeInPlotArea:(FMPlotArea *)area minValue:(CGFloat)min
{
    [self.attributes setDepthValue:min+0.05];
    return 0.1;
}

- (UniformBarAttributes *)attributes { return _bar.attributes; }

- (id<Series>)series { return [_bar series]; }

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder projection:(UniformProjection *)projection
{
    [_bar encodeWith:encoder projection:projection];
}

+ (instancetype)orderedSeriesWithCapacity:(NSUInteger)capacity
								   engine:(Engine *)engine
{
	OrderedSeries *series = [[OrderedSeries alloc] initWithResource:engine.resource
													 vertexCapacity:capacity];
	OrderedBarPrimitive *bar = [[OrderedBarPrimitive alloc] initWithEngine:engine
																	 series:series
																 attributes:nil];
	
	return [[self alloc] initWithBar:bar];
}


@end




@implementation FMPointSeries

- (instancetype)initWithPoint:(PointPrimitive *)point
{
    self = [super init];
    if(self) {
        _point = point;
    }
    return self;
}

- (UniformPointAttributes *)attributes { return _point.attributes; }
- (id<Series>)series { return [_point series]; }

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder projection:(UniformProjection *)projection
{
    [_point encodeWith:encoder projection:projection];
}

+ (instancetype)orderedSeriesWithCapacity:(NSUInteger)capacity
								   engine:(Engine *)engine
{
	OrderedSeries *series = [[OrderedSeries alloc] initWithResource:engine.resource
													 vertexCapacity:capacity];
	OrderedPointPrimitive *point = [[OrderedPointPrimitive alloc] initWithEngine:engine
																		  series:series
																	  attributes:nil];
	
	return [[self alloc] initWithPoint:point];
}

@end




@implementation FMPlotArea

- (instancetype)initWithPlotRect:(PlotRect *)rect
{
    self = [super init];
    if(self) {
        DeviceResource *res = rect.engine.resource;
        _projection = [[UniformProjection alloc] initWithResource:res];
        _rect = rect;
    }
    return self;
}

- (UniformPlotRectAttributes *)attributes { return _rect.attributes; }

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
             chart:(MetalChart *)chart
              view:(MTKView *)view
{
    [_projection setPhysicalSize:view.bounds.size];
    [_projection setSampleCount:view.sampleCount];
    [_projection setColorPixelFormat:view.colorPixelFormat];
    [_projection setPadding:chart.padding];
    
    [_rect encodeWith:encoder projection:_projection];
}

- (CGFloat)requestDepthRangeFrom:(CGFloat)min objects:(NSArray * _Nonnull)objects
{
    CGFloat currentValue = 0;
    for(id obj in objects) {
        if([obj conformsToProtocol:@protocol(FMPlotAreaClient)]) {
            CGFloat v = [(id<FMPlotAreaClient>)obj allocateRangeInPlotArea:self minValue:(min+currentValue)];
            currentValue += fabs(v);
        }
    }
    [self.attributes setDepthValue:min];
    return -currentValue;
}

+ (instancetype)rectWithEngine:(Engine *)engine
{
	PlotRect *rect = [[PlotRect alloc] initWithEngine:engine];
	return [[self alloc] initWithPlotRect:rect];
}

@end

@interface FMGridLine()

@property (readonly, nonatomic) FMDimensionalProjection *dimension;

@end

@implementation FMGridLine

- (instancetype)initWithGridLine:(GridLine *)gridLine
                      Projection:(FMSpatialProjection *)projection
                       dimension:(NSInteger)dimensionId
{
    self = [super init];
    if(self) {
        _gridLine = gridLine;
        _projection = projection;
        _dimension = [projection dimensionWithId:dimensionId];
        
        if(_dimension == nil) {
            abort();
        }
        
        const NSUInteger dimIndex = [projection.dimensions indexOfObject:_dimension];
        [_gridLine.attributes setDimensionIndex:dimIndex];
    }
    return self;
}

- (UniformGridAttributes *)attributes {
    return self.gridLine.attributes;
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
             chart:(MetalChart *)chart
              view:(MTKView *)view
{
    const CGFloat len = _dimension.max - _dimension.min;
    const NSUInteger maxCount = floor(len/_gridLine.attributes.interval) + 1;
    [_gridLine encodeWith:encoder projection:_projection.projection maxCount:maxCount];
}

- (CGFloat)requestDepthRangeFrom:(CGFloat)min objects:(NSArray * _Nonnull)objects
{
    for(id obj in objects) {
        if([obj isKindOfClass:[FMPlotArea class]]) {
            return 0;
        }
    }
    [self.attributes setDepthValue:min+0.05];
    return 0.1;
}

- (CGFloat)allocateRangeInPlotArea:(FMPlotArea *)area minValue:(CGFloat)min
{
    [self.attributes setDepthValue:min+0.05];
    return 0.1;
}

+ (instancetype)gridLineWithEngine:(Engine *)engine
                        projection:(FMSpatialProjection *)projection
                         dimension:(NSInteger)dimensionId
{
    GridLine *line = [[GridLine alloc] initWithEngine:engine];
    return [[self alloc] initWithGridLine:line Projection:projection dimension:dimensionId];
}

@end
