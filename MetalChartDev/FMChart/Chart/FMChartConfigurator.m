//
//  FMUtility.m
//  FMChart
//
//  Created by Keisuke Mori on 2015/09/20.
//  Copyright © 2015 Keisuke Mori. All rights reserved.
//

#import "FMChartConfigurator.h"
#import "FMMetalChart.h"
#import "FMProjectionUpdater.h"
#import "FMAxis.h"
#import "FMAxisLabel.h"
#import "FMRenderables.h"
#import "FMInteractive.h"
#import "FMAnimator.h"
#import "Engine.h"
#import "DeviceResource.h"
#import "Rects.h"
#import "RectBuffers.h"
#import "LineBuffers.h"
#import "PointBuffers.h"
#import "Lines.h"
#import "Rects.h"
#import "Points.h"
#import "Series.h"



@implementation FMDimension

- (instancetype)initWithId:(NSInteger)dimensionId filters:(NSArray<id<FMRangeFilter>> *)filters
{
	self = [super init];
	if(self) {
		_dim = [[FMDimensionalProjection alloc] initWithDimensionId:dimensionId minValue:-1 maxValue:1];
		_updater = [[FMProjectionUpdater alloc] initWithTarget:_dim];
		for(id<FMRangeFilter> f in filters) {
			[_updater addFilterToLast:f];
		}
		[_updater updateTarget];
	}
	return self;
}

+ (instancetype)dimensionWithId:(NSInteger)dimensionId filters:(NSArray<id<FMRangeFilter>> *)filters
{
	return [[self alloc] initWithId:dimensionId filters:filters];
}

- (void)addValue:(CGFloat)value
{
	[self.updater addSourceValue:value update:NO];
}

- (void)clearValues
{
	[self.updater clearSourceValues:NO];
}

- (void)updateRange
{
	[self.updater updateTarget];
}

@end



@implementation FMSpace2D

- (instancetype)initWithDimX:(FMDimension*)x Y:(FMDimension*)y resource:(FMDeviceResource*)resource
{
	self = [super init];
	if(self) {
		_x = x;
		_y = y;
		_space = [[FMProjectionCartesian2D alloc] initWithDimensionX:x.dim Y:y.dim resource:resource];
	}
	return self;
}

+ (instancetype)spaceWithDimensionX:(FMDimension *)x Y:(FMDimension *)y engine:(FMDeviceResource *)resource
{
	return [[self alloc] initWithDimX:x Y:y resource:resource];
}

- (void)addValueX:(CGFloat)x Y:(CGFloat)y
{
	[self.x addValue:x];
	[self.y addValue:y];
}

- (void)clearValues
{
	[self.x clearValues];
	[self.y clearValues];
}

- (void)updateRanges
{
	[self.x updateRange];
	[self.y updateRange];
	[self.metalView setNeedsDisplay];
}

- (BOOL)containsDimension:(FMDimension *)dim
{
	return (self.x == dim || self.y == dim);
}

@end



@interface FMChartConfigurator()

@property (nonatomic, readonly) NSMutableArray *retained;

@end

@implementation FMChartConfigurator

+ (void)configureMetalView:(FMMetalView *)view
			  preferredFps:(NSInteger)fps
				   surface:(FMSurfaceConfiguration *)surface
{
	view.enableSetNeedsDisplay = (fps <= 0);
	view.paused = (fps <= 0);
	view.preferredFramesPerSecond = fps;
	view.colorPixelFormat = surface.colorPixelFormat;
	view.depthStencilPixelFormat = determineDepthPixelFormat();
	view.sampleCount = surface.sampleCount;
	view.clearDepth = 0;
	view.layer.magnificationFilter = kCAFilterNearest;
}

- (instancetype)initWithChart:(FMMetalChart *)chart
					   engine:(FMEngine *)engine
						view:(FMMetalView *)view
				 preferredFps:(NSInteger)fps
{
	self = [super init];
	if(self) {
		_chart = chart;
		_dimensions = [NSArray array];
		_space = [NSArray array];
		_retained = [NSMutableArray array];
		FMDeviceResource *res = [FMDeviceResource defaultResource];
		engine = (engine) ? engine : [[FMEngine alloc] initWithResource:res surface:[FMSurfaceConfiguration defaultConfiguration]];
		_engine = engine;
		_preferredFps = fps;
		FMAnimator *animator = [[FMAnimator alloc] init];
		animator.metalView = view;
		chart.bufferHook = animator;
		_animator = animator;
		_dispatcher = [[FMGestureDispatcher alloc] initWithPanRecognizer:nil
														 pinchRecognizer:nil];
		_dispatcher.animator = animator;
		_view = view;
		
		if(view) {
			[self.class configureMetalView:view preferredFps:fps surface:engine.surface];
			view.device = engine.resource.device;
			view.delegate = chart;
		}
	}
	return self;
}

- (FMSpace2D *)spaceWithDimX:(FMDimension *)x Y:(FMDimension *)y
{
	NSArray<NSNumber*>* ids = @[@(x.dim.dimensionId), @(y.dim.dimensionId)];
	
	for(FMSpace2D *s in self.space) {
		if([s.space matchesDimensionIds:ids]) {
			return s;
		}
	}
	FMSpace2D *space = [FMSpace2D spaceWithDimensionX:x Y:y engine:self.engine.resource];
	space.metalView = self.view;
	_space = [_space arrayByAddingObject:space];
	[_chart addProjection:space.space];
	return space;
}

- (FMSpace2D *)findSpaceWithIdX:(NSInteger)x Y:(NSInteger)y
{
	NSArray<NSNumber*>* ids = @[@(x), @(y)];
	NSArray<FMSpace2D*> *space = self.space;
	for(FMSpace2D *s in space) {
		if([s.space matchesDimensionIds:ids]) {
			return s;
		}
	}
	return nil;
}

- (FMDimension *)dimWithId:(NSInteger)dimensionId
{
	NSArray *dims = self.dimensions;
	FMDimension *r = nil;
	for(FMDimension *dim in dims) {
		if(dim.dim.dimensionId == dimensionId) {
			r = dim;
			break;
		}
	}
	return r;
}

- (FMDimension *)createDimWithId:(NSInteger)dimensionId filters:(NSArray<id<FMRangeFilter>> *)filters
{
	FMDimension *r = [self dimWithId:dimensionId];
	if(r == nil) {
		r = [FMDimension dimensionWithId:dimensionId filters:filters];
		_dimensions = [_dimensions arrayByAddingObject:r];
	}
	return r;
}

- (void)clearValuesForAllDimensions
{
	typeof(self.dimensions) dims = self.dimensions;
	for(FMDimension *d in dims) {
		[d clearValues];
	}
}

- (void)bindGestureRecognizersPan:(FMPanGestureRecognizer *)pan pinch:(UIPinchGestureRecognizer *)pinch
{
	[self.view addGestureRecognizer:pan];
	[self.view addGestureRecognizer:pinch];
	FMGestureDispatcher *dispatcher = _dispatcher;
	dispatcher.panRecognizer = pan;
	dispatcher.pinchRecognizer = pinch;
}

- (FMWindowFilter*)addWindowToDim:(FMDimension *)dim
						   length:(FMScaledWindowLength *)length
						 position:(FMAnchoredWindowPosition *)position
					   horizontal:(BOOL)horizontal
{
	if(dim) {
		const FMDimOrientation orientation = (horizontal) ? FMDimOrientationHorizontal : FMDimOrientationVertical;
		FMWindowFilter *filter = [[FMWindowFilter alloc] initWithOrientation:orientation
																		view:self.view
																	 padding:self.chart.padding
															  lengthDelegate:length
															positionDelegate:position];
		[dim.updater addFilterToLast:filter];
		[self addRetainedObject:length];
		[self addRetainedObject:position];
		
		[_dispatcher addPanListener:position orientation:orientation];
		[_dispatcher addScaleListener:length orientation:orientation];
		
		length.view = self.view;
		length.updater = dim.updater;
		position.view = self.view;
		position.updater = dim.updater;
		
		return filter;
	}
	return nil;
}

- (FMSpace2D *)firstSpaceContainingDimensionWithId:(NSInteger)dimensionId
{
	FMDimension *dim = [self dimWithId:dimensionId];
	if(dim) {
		NSArray<FMSpace2D*> *space = self.space;
		for(FMSpace2D *s in space) {
			if([s containsDimension:dim]) {
				return s;
			}
		}
	}
	return nil;
}

- (FMExclusiveAxis *)addAxisToDimWithId:(NSInteger)dimensionId
							belowSeries:(BOOL)below
						   configurator:(id<FMAxisConfigurator>)configurator
								  label:(FMAxisLabelDelegateBlock)block
{
	return [self addAxisToDimWithId:dimensionId belowSeries:below configurator:configurator labelFrameSize:CGSizeMake(45, 30) labelBufferCount:8 label:block];
}

- (FMExclusiveAxis *)addAxisToDimWithId:(NSInteger)dimensionId
							belowSeries:(BOOL)below
						   configurator:(id<FMAxisConfigurator>)configurator
						 labelFrameSize:(CGSize)size
					   labelBufferCount:(NSUInteger)count
								  label:(FMAxisLabelDelegateBlock)block
{
	FMDimension *dim = [self dimWithId:dimensionId];
	if(dim) {
		FMSpace2D *targetSpace = [self firstSpaceContainingDimensionWithId:dimensionId];
		NSUInteger dimIndex = [targetSpace.space.dimensions indexOfObject:dim.dim];
		if(targetSpace) {
			FMExclusiveAxis *axis = [[FMExclusiveAxis alloc] initWithEngine:_engine Projection:targetSpace.space dimension:dimensionId configuration:configurator];
			if(below) {
				[_chart addPreRenderable:axis];
			} else {
				[_chart addPostRenderable:axis];
			}
			if(block) {
				FMAxisLabelBlockDelegate *delegate = [[FMAxisLabelBlockDelegate alloc] initWithBlock:block];
				FMAxisLabel *label = [[FMAxisLabel alloc] initWithEngine:_engine
															   frameSize:size
														  bufferCapacity:count
														   labelDelegate:delegate];
				[label setFrameAnchorPoint:((dimIndex == 0) ? CGPointMake(0.5, 0) : CGPointMake(1.0, 0.5))];
				label.axis = axis;
				[self addRetainedObject:delegate];
				[self addRetainedObject:label];
				if(below) {
					[_chart addPreRenderable:label];
				} else {
					[_chart addPostRenderable:label];
				}
			}
			return axis;
		}
	}
	return nil;
}

- (NSArray<FMAxisLabel *> *)axisLabelsToAxis:(id<FMAxis>)axis
{
	NSMutableArray<FMAxisLabel *> *ar = nil;
	NSArray *retained = self.retained.copy;
	for(id obj in retained) {
		if([obj isKindOfClass:[FMAxisLabel class]]) {
			FMAxisLabel *label = obj;
			if(label.axis == axis) {
				ar = (ar) ? ar : [NSMutableArray array];
				[ar addObject:label];
			}
		}
	}
	return ar.copy;
}

- (FMPlotArea *)addPlotAreaWithColor:(UIColor *)color
{
	FMPlotRectPrimitive *rect = [[FMPlotRectPrimitive alloc] initWithEngine:_engine];
	FMPlotArea *area = [[FMPlotArea alloc] initWithPlotRect:rect];
	CGFloat r, g, b, a;
	if([color getRed:&r green:&g blue:&b alpha:&a]) {
		[area.attributes setColorRed:r green:g blue:b alpha:a];
	} else {
		CGFloat v;
		if([color getWhite:&v alpha:&a]) {
			[area.attributes setColorRed:v green:v blue:v alpha:a];
		}
	}
	[_chart insertPreRenderable:area atIndex:0];
	return area;
}

- (FMGridLine *)addGridLineToDimensionWithId:(NSInteger)dimensionId
								 belowSeries:(BOOL)below
									  anchor:(CGFloat)anchorValue
									interval:(CGFloat)interval
{
	FMSpace2D *space = [self firstSpaceContainingDimensionWithId:dimensionId];
	if(space) {
		FMGridLine *line = [FMGridLine gridLineWithEngine:self.engine projection:space.space dimension:dimensionId];
		[line.configuration setAnchorValue:anchorValue];
		[line.configuration setInterval:interval];
		if(below) {
			[_chart addPreRenderable:line];
		} else {
			[_chart addPostRenderable:line];
		}
		return line;
	}
	return nil;
}

- (FMLineSeries<FMOrderedPolyLinePrimitive *> *)addLineToSpace:(FMSpace2D *)space
														series:(FMOrderedSeries *)series
{
	FMOrderedPolyLinePrimitive *line = [[FMOrderedPolyLinePrimitive alloc] initWithEngine:self.engine orderedSeries:series attributes:nil];
	FMLineSeries<FMOrderedPolyLinePrimitive*> *ls = [[FMLineSeries alloc] initWithLine:line projection:space.space];
	[_chart addRenderable:ls];
	[_chart addProjection:space.space];
	return ls;
}

- (FMLineSeries<FMOrderedAttributedPolyLinePrimitive *>*)addAttributedLineToSpace:(FMSpace2D *)space
																		   series:(FMOrderedAttributedSeries *)series
															   attributesCapacity:(NSUInteger)capacity
{
	FMOrderedAttributedPolyLinePrimitive *line = [[FMOrderedAttributedPolyLinePrimitive alloc] initWithEngine:self.engine orderedSeries:series attributesCapacity:capacity];
	FMLineSeries<FMOrderedAttributedPolyLinePrimitive*> *ls = [[FMLineSeries alloc] initWithLine:line projection:space.space];
	[_chart addRenderable:ls];
	[_chart addProjection:space.space];
	return ls;
}

- (FMUniformPointAttributes*)setPointToLine:(FMOrderedPolyLinePrimitive *)line
{
	FMUniformPointAttributes *attrs = [[FMUniformPointAttributes alloc] initWithResource:self.engine.resource];
	line.pointAttributes = attrs;
	return attrs;
}

- (FMBarSeries<FMOrderedBarPrimitive *>*)addBarToSpace:(FMSpace2D *)space
								  series:(FMOrderedSeries *)series
{
	FMOrderedBarPrimitive *bar = [[FMOrderedBarPrimitive alloc] initWithEngine:self.engine
																 series:series
														  configuration:nil
															 attributes:nil];
	FMBarSeries<FMOrderedBarPrimitive*> *bs = [[FMBarSeries alloc] initWithBar:bar projection:space.space];
	[_chart addRenderable:bs];
	[_chart addProjection:space.space];
	return bs;
}

- (FMBarSeries<FMOrderedAttributedBarPrimitive *>*)addAttributedBarToSpace:(FMSpace2D *)space
													  series:(FMOrderedAttributedSeries *)series
										  attributesCapacity:(NSUInteger)capacity
{
	FMOrderedAttributedBarPrimitive *bar = [[FMOrderedAttributedBarPrimitive alloc] initWithEngine:self.engine
																							series:series
																					 configuration:nil
																				   attributesArray:nil
																		attributesCapacityOnCreate:capacity];
	FMBarSeries<FMOrderedAttributedBarPrimitive*> *bs = [[FMBarSeries alloc] initWithBar:bar projection:space.space];
	[_chart addRenderable:bs];
	[_chart addProjection:space.space];
	return bs;
}

- (FMPointSeries<FMOrderedPointPrimitive *>*)addPointToSpace:(FMSpace2D *)space series:(FMOrderedSeries *)series
{
	FMOrderedPointPrimitive *point = [[FMOrderedPointPrimitive alloc] initWithEngine:self.engine series:series attributes:nil];
	FMPointSeries<FMOrderedPointPrimitive*> *ps = [[FMPointSeries alloc] initWithPoint:point projection:space.space];
	[_chart addRenderable:ps];
	[_chart addProjection:space.space];
	return ps;
}

- (FMPointSeries<FMOrderedAttributedPointPrimitive *>*)addAttributedPointToSpace:(FMSpace2D *)space
														  series:(FMOrderedAttributedSeries *)series
											  attributesCapacity:(NSUInteger)capacity
{
	FMOrderedAttributedPointPrimitive *point = [[FMOrderedAttributedPointPrimitive alloc] initWithEngine:self.engine series:series attributesCapacity:capacity];
	FMPointSeries<FMOrderedAttributedPointPrimitive*> *ps = [[FMPointSeries alloc] initWithPoint:point projection:space.space];
	[_chart addRenderable:ps];
	[_chart addProjection:space.space];
	return ps;
}

- (void)removeRenderable:(id<FMRenderable>)renderable
{
	[_chart removeRenderable:renderable];
}

- (FMBlockRenderable *)addBlockRenderable:(FMRenderBlock)block
{
	FMBlockRenderable *renderable = [[FMBlockRenderable alloc] initWithBlock:block];
	[_chart addRenderable:renderable];
	
	return renderable;
}

- (FMOrderedSeries *)createSeries:(NSUInteger)capacity
{
	return [[FMOrderedSeries alloc] initWithResource:self.engine.resource vertexCapacity:capacity];
}

- (FMOrderedAttributedSeries *)createAttributedSeries:(NSUInteger)capacity
{
	return [[FMOrderedAttributedSeries alloc] initWithResource:self.engine.resource vertexCapacity:capacity];
}

- (FMProjectionPolar *)addPolarSpace
{
	FMProjectionPolar *space = [[FMProjectionPolar alloc] initWithResource:self.engine.resource];
	[_chart addProjection:space];
	return space;
}

- (FMPieDoughnutSeries *)addPieSeriesToSpace:(FMProjectionPolar *)space
									capacity:(NSUInteger)capacity
{
	FMPieDoughnutSeries *series = [[FMPieDoughnutSeries alloc] initWithEngine:self.engine arc:nil projection:space values:nil attributesCapacityOnCreate:capacity valuesCapacityOnCreate:capacity];
	[_chart addRenderable:series];
	return series;
}

- (void)addRetainedObject:(id)object
{
	[self.retained addObject:object];
}

@end



