//
//  MCUtility.m
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/09/20.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "MCUtility.h"
#import "MetalChart.h"
#import "MCProjectionUpdater.h"
#import "MCAxis.h"
#import "MCAxisLabel.h"
#import "MCRenderables.h"
#import "MCInteractive.h"
#import "Engine.h"
#import "DeviceResource.h"
#import "Rects.h"
#import "RectBuffers.h"

@implementation MCUtility

@end


@interface MCConfigurator()

@end

@implementation MCConfigurator

- (instancetype)initWithChart:(MetalChart *)chart
					   engine:(Engine *)engine
						view:(MTKView *)view
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
		_view.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
		_view.clearDepth = 0;
	}
	return self;
}

- (MCSpatialProjection *)spaceWithDimensionIds:(NSArray<NSNumber *> *)ids
								configureBlock:(DimensionConfigureBlock)block
{
	for(MCSpatialProjection *s in self.space) {
		if([s matchesDimensionIds:ids]) {
			return s;
		}
	}
	NSMutableArray<MCDimensionalProjection*> *dims = [NSMutableArray array];
	for(NSNumber *dimId in ids) {
		MCDimensionalProjection *dim = [self dimensionWithId:dimId.integerValue confBlock:block];
		[dims addObject:dim];
	}
	MCSpatialProjection *space = [[MCSpatialProjection alloc] initWithDimensions:dims];
	_space = [_space arrayByAddingObject:space];
	return space;
}

- (MCDimensionalProjection *)dimensionWithId:(NSInteger)dimensionId
{
	NSArray *dims = self.dimensions;
	MCDimensionalProjection *r = nil;
	for(MCDimensionalProjection *dim in dims) {
		if(dim.dimensionId == dimensionId) {
			r = dim;
			break;
		}
	}
	return r;
}

- (MCDimensionalProjection *)dimensionWithId:(NSInteger)dimensionId confBlock:(DimensionConfigureBlock)block
{
	MCDimensionalProjection *r = [self dimensionWithId:dimensionId];
	if(r == nil) {
		r = [[MCDimensionalProjection alloc] initWithDimensionId:dimensionId minValue:-1 maxValue:1];
		if(block) {
			MCProjectionUpdater *updater = block(dimensionId);
			if(updater) {
				_updaters = [_updaters arrayByAddingObject:updater];
				updater.target = r;
			}
		}
		_dimensions = [_dimensions arrayByAddingObject:r];
	}
	return r;
}

- (MCProjectionUpdater *)updaterWithDimensionId:(NSInteger)dimensionId
{
	NSArray<MCProjectionUpdater *> *updaters = self.updaters;
	for(MCProjectionUpdater *u in updaters) {
		if(u.target.dimensionId == dimensionId) {
			 return u;
		}
	}
	return nil;
}

- (id<MCInteraction>)connectSpace:(NSArray<MCSpatialProjection *> *)space
					toInterpreter:(MCGestureInterpreter *)interpreter
{
	NSArray<MCSpatialProjection *> *ar = self.space;
	NSMutableArray<NSNumber*> * orientations = [NSMutableArray array];
	NSMutableArray<MCProjectionUpdater*> *updaters = [NSMutableArray array];
	for(MCSpatialProjection *s in space) {
		if([ar containsObject:s]) {
			MCProjectionUpdater *x = [self updaterWithDimensionId:s.dimensions[0].dimensionId];
			MCProjectionUpdater *y = [self updaterWithDimensionId:s.dimensions[1].dimensionId];
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
	id<MCInteraction> r = nil;
	if(updaters.count > 0) {
		r = [MCSimpleBlockInteraction connectUpdaters:updaters
										toInterpreter:interpreter
										 orientations:orientations];
		const BOOL setNeedsDisplay = (_preferredFps <= 0);
		if(setNeedsDisplay) {
			MTKView *view = _view;
			[interpreter addInteraction:[[MCSimpleBlockInteraction alloc] initWithBlock:^(MCGestureInterpreter * _Nonnull _interpreter) {
				[view setNeedsDisplay];
			}]];
		}
	}
	return r;
}

- (MCAxis *)addAxisToDimensionWithId:(NSInteger)dimensionId
						 belowSeries:(BOOL)below
						configurator:(id<MCAxisConfigurator>)configurator
						 label:(MCAxisLabelDelegateBlock)block
{
	MCDimensionalProjection *dim = [self dimensionWithId:dimensionId];
	if(dim) {
		MCSpatialProjection *targetSpace;
		NSArray<MCSpatialProjection*> *space = self.space;
		NSUInteger dimIndex = 0;
		for(MCSpatialProjection *s in space) {
			if([s.dimensions containsObject:dim]) {
				dimIndex = [s.dimensions indexOfObject:dim];
				targetSpace = s;
				break;
			}
		}
		if(targetSpace) {
			MCAxis *axis = [[MCAxis alloc] initWithEngine:_engine Projection:targetSpace dimension:dimensionId configuration:configurator];
			if(below) {
				[_chart addPreRenderable:axis];
			} else {
				[_chart addPostRenderable:axis];
			}
			if(block) {
				MCAxisLabelBlockDelegate *delegate = [[MCAxisLabelBlockDelegate alloc] initWithBlock:block];
				MCAxisLabel *label = [[MCAxisLabel alloc] initWithEngine:_engine
															   frameSize:CGSizeMake(45, 15)
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

- (MCPlotArea *)addPlotAreaWithColor:(UIColor *)color
{
	PlotRect *rect = [[PlotRect alloc] initWithEngine:_engine];
	MCPlotArea *area = [[MCPlotArea alloc] initWithPlotRect:rect];
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

- (MCGestureInterpreter *)addInterpreterToPanRecognizer:(UIPanGestureRecognizer *)pan
										pinchRecognizer:(UIPinchGestureRecognizer *)pinch
									   stateRestriction:(id<MCInterpreterStateRestriction>)restriction
{
	MCGestureInterpreter *interpreter = [[MCGestureInterpreter alloc] initWithPanRecognizer:pan
																			pinchRecognizer:pinch
																				restriction:restriction];
	[_view addGestureRecognizer:pan];
	[_view addGestureRecognizer:pinch];
	return interpreter;
}

@end

