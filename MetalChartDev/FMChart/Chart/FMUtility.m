//
//  FMUtility.m
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/09/20.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "FMUtility.h"
#import "MetalChart.h"
#import "FMProjectionUpdater.h"
#import "FMAxis.h"
#import "FMAxisLabel.h"
#import "FMRenderables.h"
#import "FMInteractive.h"
#import "Engine.h"
#import "DeviceResource.h"
#import "Rects.h"
#import "RectBuffers.h"
#import "LineBuffers.h"
#import "Lines.h"
#import "Rects.h"
#import "Points.h"
#import "Series.h"

@implementation FMUtility

@end


@interface FMConfigurator()

@end

@implementation FMConfigurator

- (instancetype)initWithChart:(MetalChart *)chart
					   engine:(Engine *)engine
						view:(MetalView *)view
				 preferredFps:(NSInteger)fps
{
	self = [super init];
	if(self) {
		_chart = chart;
		NSArray *array = [NSArray array];
		_dimensions = array;
		_updaters = array;
		_space = array;
		DeviceResource *res = [DeviceResource defaultResource];
		_engine = (engine) ? engine : [[Engine alloc] initWithResource:res];
		_view = view;
		_preferredFps = fps;
		
		_view.enableSetNeedsDisplay = (fps <= 0);
		_view.paused = (fps <= 0);
		_view.preferredFramesPerSecond = fps;
		_view.delegate = chart;
		_view.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
		_view.depthStencilPixelFormat = determineDepthPixelFormat();
		_view.clearDepth = 0;
	}
	return self;
}

- (FMSpatialProjection *)spaceWithDimensionIds:(NSArray<NSNumber *> *)ids
								configureBlock:(DimensionConfigureBlock)block
{
	for(FMSpatialProjection *s in self.space) {
		if([s matchesDimensionIds:ids]) {
			return s;
		}
	}
	NSMutableArray<FMDimensionalProjection*> *dims = [NSMutableArray array];
	for(NSNumber *dimId in ids) {
		FMDimensionalProjection *dim = [self dimensionWithId:dimId.integerValue confBlock:block];
		[dims addObject:dim];
	}
	FMSpatialProjection *space = [[FMSpatialProjection alloc] initWithDimensions:dims];
	_space = [_space arrayByAddingObject:space];
	return space;
}

- (FMDimensionalProjection *)dimensionWithId:(NSInteger)dimensionId
{
	NSArray *dims = self.dimensions;
	FMDimensionalProjection *r = nil;
	for(FMDimensionalProjection *dim in dims) {
		if(dim.dimensionId == dimensionId) {
			r = dim;
			break;
		}
	}
	return r;
}

- (FMDimensionalProjection *)dimensionWithId:(NSInteger)dimensionId confBlock:(DimensionConfigureBlock)block
{
	FMDimensionalProjection *r = [self dimensionWithId:dimensionId];
	if(r == nil) {
		r = [[FMDimensionalProjection alloc] initWithDimensionId:dimensionId minValue:-1 maxValue:1];
		if(block) {
			FMProjectionUpdater *updater = block(dimensionId);
			if(updater) {
				_updaters = [_updaters arrayByAddingObject:updater];
				updater.target = r;
                [updater updateTarget];
			}
		}
		_dimensions = [_dimensions arrayByAddingObject:r];
	}
	return r;
}

- (FMProjectionUpdater *)updaterWithDimensionId:(NSInteger)dimensionId
{
	NSArray<FMProjectionUpdater *> *updaters = self.updaters;
	for(FMProjectionUpdater *u in updaters) {
		if(u.target.dimensionId == dimensionId) {
			 return u;
		}
	}
	return nil;
}

- (id<FMInteraction>)connectSpace:(NSArray<FMSpatialProjection *> *)space
					toInterpreter:(FMGestureInterpreter *)interpreter
{
	NSArray<FMSpatialProjection *> *ar = self.space;
	NSMutableArray<NSNumber*> * orientations = [NSMutableArray array];
	NSMutableArray<FMProjectionUpdater*> *updaters = [NSMutableArray array];
	for(FMSpatialProjection *s in space) {
		if([ar containsObject:s]) {
			FMProjectionUpdater *x = [self updaterWithDimensionId:s.dimensions[0].dimensionId];
			FMProjectionUpdater *y = [self updaterWithDimensionId:s.dimensions[1].dimensionId];
			if(x && ![updaters containsObject:x]) {
				[updaters addObject:x];
				[orientations addObject:@(0)];
			}
			if(y && ![updaters containsObject:y]) {
				[updaters addObject:y];
				[orientations addObject:@(M_PI_2)];
			}
		}
	}
	id<FMInteraction> r = nil;
	if(updaters.count > 0) {
		r = [FMSimpleBlockInteraction connectUpdaters:updaters
										toInterpreter:interpreter
										 orientations:orientations];
		const BOOL setNeedsDisplay = (_preferredFps <= 0);
		if(setNeedsDisplay) {
			typeof(_view) view = _view;
			[interpreter addInteraction:[[FMSimpleBlockInteraction alloc] initWithBlock:^(FMGestureInterpreter * _Nonnull _interpreter) {
				[view setNeedsDisplay];
			}]];
		}
	}
	return r;
}

- (FMSpatialProjection *)firstSpaceContainingDimensionWithId:(NSInteger)dimensionId
{
    FMDimensionalProjection *dim = [self dimensionWithId:dimensionId];
    if(dim) {
        NSArray<FMSpatialProjection*> *space = self.space;
        for(FMSpatialProjection *s in space) {
            if([s.dimensions containsObject:dim]) {
                return s;
            }
        }
    }
    return nil;
}

- (FMAxis *)addAxisToDimensionWithId:(NSInteger)dimensionId
						 belowSeries:(BOOL)below
						configurator:(id<FMAxisConfigurator>)configurator
						 label:(FMAxisLabelDelegateBlock)block
{
	FMDimensionalProjection *dim = [self dimensionWithId:dimensionId];
	if(dim) {
		FMSpatialProjection *targetSpace = [self firstSpaceContainingDimensionWithId:dimensionId];
		NSUInteger dimIndex = [targetSpace.dimensions indexOfObject:dim];
		if(targetSpace) {
			FMAxis *axis = [[FMAxis alloc] initWithEngine:_engine Projection:targetSpace dimension:dimensionId configuration:configurator];
			if(below) {
				[_chart addPreRenderable:axis];
			} else {
				[_chart addPostRenderable:axis];
			}
			if(block) {
				FMAxisLabelBlockDelegate *delegate = [[FMAxisLabelBlockDelegate alloc] initWithBlock:block];
				FMAxisLabel *label = [[FMAxisLabel alloc] initWithEngine:_engine
															   frameSize:CGSizeMake(45, 30)
														  bufferCapacity:12
														   labelDelegate:delegate];
				[label setFrameAnchorPoint:((dimIndex == 0) ? CGPointMake(0.5, 0) : CGPointMake(1.0, 0.5))];
				axis.decoration = label;
			}
			return axis;
		}
	}
	return nil;
}

- (FMPlotArea *)addPlotAreaWithColor:(UIColor *)color
{
	PlotRect *rect = [[PlotRect alloc] initWithEngine:_engine];
	FMPlotArea *area = [[FMPlotArea alloc] initWithPlotRect:rect];
	CGFloat r, g, b, a;
	if([color getRed:&r green:&g blue:&b alpha:&a]) {
		[area.attributes setColor:r green:g blue:b alpha:a];
	} else {
		CGFloat v;
		if([color getWhite:&v alpha:&a]) {
			[area.attributes setColor:v green:v blue:v alpha:a];
		}
	}
	[_chart insertPreRenderable:area atIndex:0];
	return area;
}

- (FMGestureInterpreter *)addInterpreterToPanRecognizer:(UIPanGestureRecognizer *)pan
										pinchRecognizer:(UIPinchGestureRecognizer *)pinch
									   stateRestriction:(id<FMInterpreterStateRestriction>)restriction
{
	FMGestureInterpreter *interpreter = [[FMGestureInterpreter alloc] initWithPanRecognizer:pan
																			pinchRecognizer:pinch
																				restriction:restriction];
	[_view addGestureRecognizer:pan];
	[_view addGestureRecognizer:pinch];
	return interpreter;
}

- (FMGridLine *)addGridLineToDimensionWithId:(NSInteger)dimensionId
                                 belowSeries:(BOOL)below
                                      anchor:(CGFloat)anchorValue
                                    interval:(CGFloat)interval
{
    FMSpatialProjection *space = [self firstSpaceContainingDimensionWithId:dimensionId];
    if(space) {
        FMGridLine *line = [FMGridLine gridLineWithEngine:self.engine projection:space dimension:dimensionId];
        [line.attributes setAnchorValue:anchorValue];
        [line.attributes setInterval:interval];
        if(below) {
            [_chart addPreRenderable:line];
        } else {
            [_chart addPostRenderable:line];
        }
        return line;
    }
    return nil;
}

- (FMLineSeries *)addLineToSpace:(FMSpatialProjection *)space
                          series:(OrderedSeries *)series
{
    LinePrimitive *line = [[OrderedPolyLinePrimitive alloc] initWithEngine:self.engine orderedSeries:series attributes:nil];
    FMLineSeries *ls = [[FMLineSeries alloc] initWithLine:line projection:space];
    [_chart addSeries:ls];
	[_chart addProjection:space];
    return ls;
}

- (FMBarSeries *)addBarToSpace:(FMSpatialProjection *)space
                        series:(OrderedSeries *)series
{
    BarPrimitive *bar = [[OrderedBarPrimitive alloc] initWithEngine:self.engine series:series attributes:nil];
    FMBarSeries *bs = [[FMBarSeries alloc] initWithBar:bar projection:space];
    [_chart addSeries:bs];
	[_chart addProjection:space];
    return bs;
}

- (FMPointSeries *)addPointToSpace:(FMSpatialProjection *)space series:(OrderedSeries *)series
{
    PointPrimitive *point = [[OrderedPointPrimitive alloc] initWithEngine:self.engine series:series attributes:nil];
    FMPointSeries *ps = [[FMPointSeries alloc] initWithPoint:point projection:space];
    [_chart addSeries:ps];
	[_chart addProjection:space];
    return ps;
}

- (OrderedSeries *)createSeries:(NSUInteger)capacity
{
    return [[OrderedSeries alloc] initWithResource:self.engine.resource vertexCapacity:capacity];
}

@end



