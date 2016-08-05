//
//  FMRangeFilters.m
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/10.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "FMRangeFilters.h"
#import "FMProjectionUpdater.h"

@implementation FMDefaultFilter

- (instancetype)init
{
	self = [super init];
	if(self) {
		
	}
	return self;
}

- (void)updater:(FMProjectionUpdater *)updater minValue:(CGFloat *)min maxValue:(CGFloat *)max
{
	_currentMin = *min;
	_currentMax = *max;
}

- (CGFloat)currentLength
{
	return _currentMax - _currentMin;
}

- (CGFloat)currentCenter
{
	return (_currentMax + _currentMin) / 2;
}

@end

@implementation FMLengthFilter

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

- (void)updater:(FMProjectionUpdater *)updater
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

@implementation FMSourceFilter

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

- (void)updater:(FMProjectionUpdater *)updater
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

+ (instancetype)expandWithMin:(CGFloat)min max:(CGFloat)max
{
	return [[self alloc] initWithMinValue:min maxValue:max expandMin:YES expandMax:YES];
}

+ (instancetype)ifNullWithMin:(CGFloat)min max:(CGFloat)max
{
	return [[self alloc] initWithMinValue:min maxValue:max expandMin:YES expandMax:YES];
}

@end

@implementation FMPaddingFilter

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

- (void)updater:(FMProjectionUpdater *)updater
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

+ (instancetype)paddingWithLow:(CGFloat)low high:(CGFloat)high
{
	return [[self alloc] initWithPaddingLow:low high:high shrinkMin:NO shrinkMax:NO applyToCurrent:NO];
}

@end


@implementation FMIntervalFilter

- (instancetype)initWithAnchor:(CGFloat)anchor
					  interval:(CGFloat)interval
					 shrinkMin:(BOOL)shrinkMin
					 shrinkMax:(BOOL)shrinkMax
{
	self = [super init];
	if(self) {
		_anchor = anchor;
		_interval = interval;
		_shrinkMin = shrinkMin;
		_shrinkMax = shrinkMax;
	}
	return self;
}

- (void)updater:(FMProjectionUpdater *)updater
	   minValue:(CGFloat *)min
	   maxValue:(CGFloat *)max
{
	const CGFloat anchor = _anchor;
	const CGFloat interval = _interval;
	
	const CGFloat vMin = *min;
	const CGFloat rMin = fmod((vMin - anchor), interval);
	if(rMin != 0) {
		*min = (vMin - rMin) + ((_shrinkMin) ? interval : 0);
	}
	
	const CGFloat vMax = *max;
	const CGFloat rMax = fmod((vMax - anchor), interval);
	if(rMax != 0) {
		*max = (vMax - rMax) + ((_shrinkMax) ? 0 : interval);
	}
}

+ (instancetype)filterWithAnchor:(CGFloat)anchor interval:(CGFloat)interval
{
	return [[self alloc] initWithAnchor:anchor
							   interval:interval
							  shrinkMin:NO
							  shrinkMax:NO];
}

@end



@implementation FMWindowFilter

- (instancetype)initWithOrientation:(FMDimOrientation)orientation
							   view:(UIView *)view
							padding:(FMRectPadding)padding
					 lengthDelegate:(id<FMWindowLengthDelegate> _Nonnull)lenDelegate
				   positionDelegate:(id<FMWindowPositionDelegate> _Nonnull)posDelegate
{
	self = [super init];
	if(self) {
		_orientation = orientation;
		_view = view;
		_padding = padding;
		_lengthDelegate = lenDelegate;
		_positionDelegate = posDelegate;
	}
	return self;
}

- (void)updater:(FMProjectionUpdater *)updater minValue:(CGFloat *)min maxValue:(CGFloat *)max
{
	const BOOL horizontal = (_orientation == FMDimOrientationHorizontal);
	const CGFloat viewSize = (horizontal) ? _view.bounds.size.width : _view.bounds.size.height;
	const CGFloat padSize = (horizontal) ? (_padding.left + _padding.right) : (_padding.top + _padding.bottom);
	const CGFloat viewPort = viewSize - padSize;
	if(viewPort > 0) {
		id<FMWindowLengthDelegate> lenDelgate = self.lengthDelegate;
		id<FMWindowPositionDelegate> posDelegate = self.positionDelegate;
		const CGFloat vMin = *min, vMax = *max;
		
		const CGFloat length = [lenDelgate lengthForViewPort:viewPort dataRange:(vMax-vMin)];
		const CGFloat pos = [posDelegate positionInRangeWithMin:vMin max:vMax length:length];
		const CGFloat margin = (vMax - vMin) - length;
		const CGFloat newMin = vMin + (margin * pos);
		*min = newMin;
		*max = newMin + length;
	}
}

@end



@interface FMBlockFilter()

@property (copy, nonatomic) FilterBlock _Nonnull block;

@end

@implementation FMBlockFilter

- (instancetype)initWithBlock:(FilterBlock)block
{
	self = [super init];
	if(self) {
		self.block = block;
	}
	return self;
}

- (void)updater:(FMProjectionUpdater *)updater minValue:(CGFloat *)min maxValue:(CGFloat *)max
{
	_block(updater, min, max);
}

@end




