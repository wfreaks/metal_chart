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
#import "MCInteractive.h"
#import "Engine.h"
#import "DeviceResource.h"

@implementation MCUtility

@end


@interface MCConfigurator()

@end

@implementation MCConfigurator

- (instancetype)initWithChart:(MetalChart *)chart
					   engine:(Engine *)engine
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

- (MCDimensionalProjection *)dimensionWithId:(NSInteger)dimensionId confBlock:(DimensionConfigureBlock)block
{
	NSArray *dims = self.dimensions;
	MCDimensionalProjection *r = nil;
	for(MCDimensionalProjection *dim in dims) {
		if(dim.dimensionId == dimensionId) {
			r = dim;
			break;
		}
	}
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
	}
	return r;
}

@end

