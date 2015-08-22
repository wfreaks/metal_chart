//
//  MCRestrictions.m
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/10.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "MCRestrictions.h"


@implementation MCLengthRestriction

- (instancetype)initWithLength:(CGFloat)length anchor:(CGFloat)anchor offset:(CGFloat)offset
{
	self = [super init];
	if(self) {
		_length = length;
		_anchor = anchor;
		_offset = offset;
	}
	return self;
}

- (void)updater:(MCProjectionUpdater *)updater
	   minValue:(CGFloat *)min
	   maxValue:(CGFloat *)max
{
	const CGFloat mid = (*min + *max) / 2; // (min, max)が(CGFLOAT_MIN, CGFLOAT_MAX)だった場合への対処.
	const CGFloat anchorValue = mid + (_anchor * ((*max)-mid));
	const CGFloat newMin = anchorValue - ((_anchor+1) * _length * 0.5);
	const CGFloat newMax = anchorValue + ((1-_anchor) * _length * 0.5);
	*min = newMin + _offset;
	*max = newMax + _offset;
}

@end

@implementation MCSourceRestriction

- (instancetype)initWithMinValue:(CGFloat)min
						maxValue:(CGFloat)max
					   expandMin:(BOOL)expandMin
					   expandMax:(BOOL)expandMax
{
	self = [super init];
	if(self) {
		_min = min;
		_max = max;
		_expandMin = expandMin;
		_expandMax = expandMax;
	}
	return self;
}

- (void)updater:(MCProjectionUpdater *)updater
	   minValue:(CGFloat *)min
	   maxValue:(CGFloat *)max
{
	const CGFloat *minPtr = [updater sourceMinValue];
	const CGFloat *maxPtr = [updater sourceMaxValue];
	const CGFloat newMin = (minPtr == nil || (_expandMin && _min < *minPtr)) ? _min : *minPtr;
	const CGFloat newMax = (maxPtr == nil || (_expandMax && _max > *maxPtr)) ? _max : *maxPtr;
	*min = newMin;
	*max = newMax;
}

@end

@implementation MCPaddingRestriction

- (instancetype)initWithPaddingLow:(CGFloat)low
							  high:(CGFloat)high
						 shrinkMin:(BOOL)shrinkLow
						 shrinkMax:(BOOL)shrinkHigh
					applyToCurrent:(BOOL)apply
{
	self = [super init];
	if(self) {
		_paddingLow = low;
		_paddingHigh = high;
		_shrinkMin = shrinkLow;
		_shrinkMax = shrinkHigh;
		_applyToCurrentMinMax = apply;
	}
	return self;
}

- (void)updater:(MCProjectionUpdater *)updater
	   minValue:(CGFloat *)min
	   maxValue:(CGFloat *)max
{
	const CGFloat *minPtr = [updater sourceMinValue];
	const CGFloat *maxPtr = [updater sourceMaxValue];
	const BOOL apply = _applyToCurrentMinMax; // 長い.
	
	{
		const CGFloat currentMin = *min;
		CGFloat newMin = currentMin - (apply ? _paddingLow : 0);
		if(minPtr) {
			const CGFloat v = (*minPtr - _paddingLow);
			newMin = (_shrinkMin || v < newMin) ? v : newMin;
		}
		if(currentMin != newMin) {
			*min = newMin;
		}
	}
	{
		const CGFloat currentMax = *max;
		CGFloat newMax = currentMax + (apply ? _paddingHigh : 0);
		if(maxPtr) {
			const CGFloat v = (*maxPtr - _paddingHigh);
			newMax = (_shrinkMax || v > newMax) ? v : newMax;
		}
		if(currentMax != newMax) {
			*max = newMax;
		}
	}
}

@end


@interface MCBlockRestriction()

@property (copy, nonatomic) RestrictionBlock _Nonnull block;

@end

@implementation MCBlockRestriction

- (instancetype)initWithBlock:(RestrictionBlock)block
{
	self = [super init];
	if(self) {
		self.block = block;
	}
	return self;
}

- (void)updater:(MCProjectionUpdater *)updater minValue:(CGFloat *)min maxValue:(CGFloat *)max
{
	_block(updater, min, max);
}

@end

@implementation MCUserInteractiveRestriction

- (instancetype)initWithGestureInterpreter:(MCGestureInterpreter *)interpreter
							   orientation:(CGFloat)radian
{
	self = [super init];
	if(self) {
		_interpreter = interpreter;
		_orientationRad = radian;
	}
	return self;
}

- (void)updater:(MCProjectionUpdater *)updater minValue:(CGFloat *)min maxValue:(CGFloat *)max
{
	
}

@end




