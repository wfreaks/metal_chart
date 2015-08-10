//
//  MCRestrictions.m
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/10.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "MCRestrictions.h"


@implementation MCLengthRestriction

- (instancetype)initWithLength:(CGFloat)length anchor:(CGFloat)anchor
{
	self = [super init];
	if(self) {
		_length = length;
		_anchor = anchor;
	}
	return self;
}

- (void)updater:(MCProjectionUpdater *)updater
	   minValue:(CGFloat *)min
	   maxValue:(CGFloat *)max
{
	const CGFloat mid = (*min + *max) / 2; // (min, max)が(CGFLOAT_MIN, CGFLOAT_MAX)だった場合への対処.
	const CGFloat anchorValue = mid + (_anchor * ((*max)-mid));
	*max = anchorValue + ((1-_anchor) * _length);
	*min = anchorValue - ((_anchor+1) * _length);
}

@end

@implementation MCAlternativeSourceRestriction

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

@implementation MCSourcePaddingRestriction

- (instancetype)initWithPaddingLow:(CGFloat)low high:(CGFloat)high applyToCurrent:(BOOL)apply shrink:(BOOL)shrink
{
	self = [super init];
	if(self) {
		_paddingLow = low;
		_paddingHigh = high;
		_allowShrink = shrink;
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
			newMin = (_allowShrink || v < newMin) ? v : newMin;
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
			newMax = (_allowShrink || v > newMax) ? v : newMax;
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

