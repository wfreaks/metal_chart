//
//  FMUtility.m
//  FMChart
//
//  Created by Keisuke Mori on 2015/09/20.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "FMChartConfigurator.h"
#import "MetalChart.h"
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


@interface FMChartConfigurator()

@property (nonatomic, readonly) NSMutableArray *retained;

// protocolを使ったdelegate/hookなどを良く実装するため、外側でretainしておく必要が
// 出る事が多いが、実際そのためにプロパティ増やすとかないわーな時に使う.
// 決して良い方法ではないし何回も通るコードパスで使用するべきではないが.
- (void)addRetainedObject:(id _Nonnull)object;


@end

@implementation FMChartConfigurator

+ (void)configureMetalView:(MetalView *)view
			  preferredFps:(NSInteger)fps
{
	view.enableSetNeedsDisplay = (fps <= 0);
	view.paused = (fps <= 0);
	view.preferredFramesPerSecond = fps;
	view.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
	view.depthStencilPixelFormat = determineDepthPixelFormat();
	view.clearDepth = 0;
}

- (instancetype)initWithChart:(MetalChart *)chart
					   engine:(FMEngine *)engine
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
		_retained = [NSMutableArray array];
		FMDeviceResource *res = [FMDeviceResource defaultResource];
		engine = (engine) ? engine : [[FMEngine alloc] initWithResource:res];
		_engine = engine;
		_preferredFps = fps;
		FMAnimator *animator = [[FMAnimator alloc] init];
		animator.metalView = view;
		chart.bufferHook = animator;
		_animator = animator;
		_view = view;
		
		if(view) {
			[self.class configureMetalView:view preferredFps:fps];
			view.device = engine.resource.device;
			view.delegate = chart;
		}
	}
	return self;
}

- (FMProjectionCartesian2D *)spaceWithDimensionIds:(NSArray<NSNumber *> *)ids
								configureBlock:(DimensionConfigureBlock)block
{
	if(ids.count != 2) return nil;
	
	for(FMProjectionCartesian2D *s in self.space) {
		if([s matchesDimensionIds:ids]) {
			return s;
		}
	}
	NSMutableArray<FMDimensionalProjection*> *dims = [NSMutableArray array];
	for(NSNumber *dimId in ids) {
		FMDimensionalProjection *dim = [self dimensionWithId:dimId.integerValue confBlock:block];
		[dims addObject:dim];
	}
	FMProjectionCartesian2D *space = [[FMProjectionCartesian2D alloc] initWithDimensionX:dims[0] Y:dims[1] resource:self.engine.resource];
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

- (id<FMInteraction>)connectSpace:(NSArray<FMProjectionCartesian2D *> *)space
					toInterpreter:(FMGestureInterpreter *)interpreter
{
	NSArray<FMProjectionCartesian2D *> *ar = self.space;
	NSMutableArray<NSNumber*> * orientations = [NSMutableArray array];
	NSMutableArray<FMProjectionUpdater*> *updaters = [NSMutableArray array];
	for(FMProjectionCartesian2D *s in space) {
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
			__weak typeof(_view) view = _view;
			[interpreter addInteraction:[[FMSimpleBlockInteraction alloc] initWithBlock:^(FMGestureInterpreter * _Nonnull _interpreter) {
				[view setNeedsDisplay];
			}]];
		}
	}
	return r;
}

- (FMProjectionCartesian2D *)firstSpaceContainingDimensionWithId:(NSInteger)dimensionId
{
	FMDimensionalProjection *dim = [self dimensionWithId:dimensionId];
	if(dim) {
		NSArray<FMProjectionCartesian2D*> *space = self.space;
		for(FMProjectionCartesian2D *s in space) {
			if([s.dimensions containsObject:dim]) {
				return s;
			}
		}
	}
	return nil;
}

- (FMExclusiveAxis *)addAxisToDimensionWithId:(NSInteger)dimensionId
								  belowSeries:(BOOL)below
								 configurator:(id<FMAxisConfigurator>)configurator
										label:(FMAxisLabelDelegateBlock)block
{
	return [self addAxisToDimensionWithId:dimensionId belowSeries:below configurator:configurator labelFrameSize:CGSizeMake(45, 30) labelBufferCount:8 label:block];
}

- (FMExclusiveAxis *)addAxisToDimensionWithId:(NSInteger)dimensionId
								  belowSeries:(BOOL)below
								 configurator:(id<FMAxisConfigurator>)configurator
							   labelFrameSize:(CGSize)size
							 labelBufferCount:(NSUInteger)count
										label:(FMAxisLabelDelegateBlock)block
{
	FMDimensionalProjection *dim = [self dimensionWithId:dimensionId];
	if(dim) {
		FMProjectionCartesian2D *targetSpace = [self firstSpaceContainingDimensionWithId:dimensionId];
		NSUInteger dimIndex = [targetSpace.dimensions indexOfObject:dim];
		if(targetSpace) {
			FMExclusiveAxis *axis = [[FMExclusiveAxis alloc] initWithEngine:_engine Projection:targetSpace dimension:dimensionId configuration:configurator];
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

- (FMGestureInterpreter *)addInterpreterToPanRecognizer:(FMPanGestureRecognizer *)pan
										pinchRecognizer:(UIPinchGestureRecognizer *)pinch
									   stateRestriction:(id<FMInterpreterStateRestriction>)restriction
{
	FMGestureInterpreter *interpreter = [[FMGestureInterpreter alloc] initWithPanRecognizer:pan
																			pinchRecognizer:pinch
																				restriction:restriction];
	interpreter.momentumAnimator = _animator;
	[self addRetainedObject:interpreter];
	[_view addGestureRecognizer:pan];
	[_view addGestureRecognizer:pinch];
	return interpreter;
}

- (FMGridLine *)addGridLineToDimensionWithId:(NSInteger)dimensionId
								 belowSeries:(BOOL)below
									  anchor:(CGFloat)anchorValue
									interval:(CGFloat)interval
{
	FMProjectionCartesian2D *space = [self firstSpaceContainingDimensionWithId:dimensionId];
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

- (FMOrderedPolyLinePrimitive *)addLineToSpace:(FMProjectionCartesian2D *)space
										series:(FMOrderedSeries *)series
{
	FMOrderedPolyLinePrimitive *line = [[FMOrderedPolyLinePrimitive alloc] initWithEngine:self.engine orderedSeries:series attributes:nil];
	FMLineSeries *ls = [[FMLineSeries alloc] initWithLine:line projection:space];
	[_chart addRenderable:ls];
	[_chart addProjection:space];
	return line;
}

- (FMUniformPointAttributes*)setPointToLine:(FMLinePrimitive *)line
{
	FMUniformPointAttributes *attrs = [[FMUniformPointAttributes alloc] initWithResource:self.engine.resource];
	line.pointAttributes = attrs;
	return attrs;
}

- (FMOrderedBarPrimitive *)addBarToSpace:(FMProjectionCartesian2D *)space
								  series:(FMOrderedSeries *)series
{
	FMOrderedBarPrimitive *bar = [[FMOrderedBarPrimitive alloc] initWithEngine:self.engine
																 series:series
														  configuration:nil
															 attributes:nil];
	FMBarSeries *bs = [[FMBarSeries alloc] initWithBar:bar projection:space];
	[_chart addRenderable:bs];
	[_chart addProjection:space];
	return bar;
}

- (FMOrderedAttributedBarPrimitive *)addAttributedBarToSpace:(FMProjectionCartesian2D *)space
													  series:(FMOrderedAttributedSeries *)series
												attrCapacity:(NSUInteger)capacity
{
	FMOrderedAttributedBarPrimitive *bar = [[FMOrderedAttributedBarPrimitive alloc] initWithEngine:self.engine
																							series:series
																					 configuration:nil
																				  globalAttributes:nil
																				   attributesArray:nil
																		attributesCapacityOnCreate:capacity];
	FMAttributedBarSeries *bs = [[FMAttributedBarSeries alloc] initWithAttributedBar:bar projection:space];
	[_chart addRenderable:bs];
	[_chart addProjection:space];
	return bar;
}

- (FMOrderedPointPrimitive *)addPointToSpace:(FMProjectionCartesian2D *)space series:(FMOrderedSeries *)series
{
	FMOrderedPointPrimitive *point = [[FMOrderedPointPrimitive alloc] initWithEngine:self.engine series:series attributes:nil];
	FMPointSeries *ps = [[FMPointSeries alloc] initWithPoint:point projection:space];
	[_chart addRenderable:ps];
	[_chart addProjection:space];
	return point;
}

- (FMOrderedAttributedPointPrimitive *)addAttributedPointToSpace:(FMProjectionCartesian2D *)space
														  series:(FMOrderedAttributedSeries *)series
											  attributesCapacity:(NSUInteger)capacity
{
	FMOrderedAttributedPointPrimitive *point = [[FMOrderedAttributedPointPrimitive alloc] initWithEngine:self.engine series:series attributesCapacity:capacity];
	FMPointSeries *ps = [[FMPointSeries alloc] initWithPoint:point projection:space];
	[_chart addRenderable:ps];
	[_chart addProjection:space];
	return point;
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



