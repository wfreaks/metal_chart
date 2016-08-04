//
//  FMProjections.m
//  FMChart
//
//  Created by Keisuke Mori on 2015/11/17.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "FMProjections.h"
#import "Buffers.h"

@interface FMDimensionalProjection()


@end


@interface FMProjectionCartesian2D()

@end


@implementation FMDimensionalProjection

- (instancetype)initWithDimensionId:(NSInteger)dimId minValue:(CGFloat)min maxValue:(CGFloat)max
{
	self = [super init];
	if(self) {
		_dimensionId = dimId;
		_min = min;
		_max = max;
	}
	return self;
}

- (void)setMin:(CGFloat)min max:(CGFloat)max
{
	_min = min;
	_max = max;
}

- (CGFloat)length { return _max - _min; }

- (CGFloat)mid { return 0.5 * (_min + _max); }

- (CGFloat)convertValue:(CGFloat)value
					 to:(FMDimensionalProjection *)to
{
	const CGFloat v = (value - _min) / self.length;
	return (to.length * v) + to.min;
}

@end


@implementation FMProjectionCartesian2D

- (instancetype)initWithDimensionX:(FMDimensionalProjection *)x
								 Y:(FMDimensionalProjection *)y
						  resource:(FMDeviceResource * _Nullable)resource
{
	self = [super init];
	if(self) {
		_dimX = x;
		_dimY = y;
		if(resource == nil) resource = [FMDeviceResource defaultResource];
		_projection = [[FMUniformProjectionCartesian2D alloc] initWithResource:resource];
		_dimensions = @[x, y];
		_key = [NSString stringWithFormat:@"%p", self];
	}
	return self;
}

- (FMDimensionalProjection *)dimensionWithId:(NSInteger)dimensionId
{
	if(_dimX.dimensionId == dimensionId) return _dimX;
	if(_dimY.dimensionId == dimensionId) return _dimY;
	return nil;
}

- (void)configure:(MetalView *)view padding:(FMRectPadding)padding
{
	FMDimensionalProjection *xDim = _dimX;
	FMDimensionalProjection *yDim = _dimY;
	[_projection setPhysicalSize:view.bounds.size];
	[_projection setPadding:padding];
	[_projection setValueScale:CGSizeMake((xDim.max-xDim.min)/2, (yDim.max-yDim.min)/2)];
	[_projection setValueOffset:CGPointMake(-(xDim.max+xDim.min)/2, -(yDim.max+yDim.min)/2)];
}

- (BOOL)matchesDimensionIds:(NSArray<NSNumber *> *)ids
{
	const NSInteger count = ids.count;
	return (count == 2 && ids[0].integerValue == _dimX.dimensionId && ids[1].integerValue == _dimY.dimensionId);
}

@end


@implementation FMProjectionPolar

- (instancetype _Nonnull)initWithResource:(FMDeviceResource *)resource
{
	self = [super init];
	if(self) {
		if(resource == nil) resource = [FMDeviceResource defaultResource];
		_projection = [[FMUniformProjectionPolar alloc] initWithResource:resource];
	}
	return self;
}

- (void)configure:(FMMetalView *)view padding:(FMRectPadding)padding
{
	[_projection setPhysicalSize:view.bounds.size];
	[_projection setPadding:padding];
}

@end







