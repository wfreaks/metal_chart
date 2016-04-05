//
//  FMRestrictions.m
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/10.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "FMRestrictions.h"
#import "FMProjectionUpdater.h"

@implementation FMDefaultRestriction

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

@implementation FMLengthRestriction

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

@implementation FMSourceRestriction

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

@end

@implementation FMPaddingRestriction

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

@end


@implementation FMIntervalRestriction

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

@end


@interface FMBlockRestriction()

@property (copy, nonatomic) RestrictionBlock _Nonnull block;

@end

@implementation FMBlockRestriction

- (instancetype)initWithBlock:(RestrictionBlock)block
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

@implementation FMUserInteractiveRestriction

- (instancetype)initWithGestureInterpreter:(FMGestureInterpreter *)interpreter
							   orientation:(CGFloat)radian
{
	self = [super init];
	if(self) {
		_interpreter = interpreter;
		_orientationRad = radian;
	}
	return self;
}

- (void)updater:(FMProjectionUpdater *)updater minValue:(CGFloat *)min maxValue:(CGFloat *)max
{
	const CGFloat minValue = *min;
	const CGFloat maxValue = *max;
	const CGFloat mid = (minValue + maxValue) / 2;
	const CGFloat len = maxValue - mid;
	const CGSize scale = _interpreter.scaleCumulative;
	const CGPoint translation = _interpreter.translationCumulative;
	
	const CGFloat rad = _orientationRad;
	// 点P(sin(rad), cos(rad))を引き伸ばされた空間上に配置した時、引き伸ばす前の空間上でのOPのノルムが求めるべき倍率.
	// ちなみにここでいう求める倍率は空間のではなくレンジの倍率なので逆数である.
	const CGFloat px = (cos(rad) / scale.width);
	const CGFloat py = (sin(rad) / scale.height);
	const CGFloat dirScale = sqrt((px*px)+(py*py));
	const CGFloat dirOffset = (cos(rad) * translation.x) + (sin(rad) * translation.y);
	const CGFloat base = (mid - (len * dirOffset * 2)); // 実際のrangeの長さはlen*2なので.
	
	*min = base - (len * dirScale);
	*max = base + (len * dirScale);
}

@end



