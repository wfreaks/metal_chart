//
//  FMProjectionUpdater.m
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/10.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "FMProjectionUpdater.h"
#import "FMProjections.h"
#import "FMRangeFilters.h"

@interface FMProjectionUpdater()

@property (assign, nonatomic) CGFloat srcMinValue;
@property (assign, nonatomic) CGFloat srcMaxValue;

@end

@implementation FMProjectionUpdater

- (instancetype)initWithTarget:(FMDimensionalProjection * _Nullable)target
{
	self = [super self];
	if(self) {
		_srcMinValue = +CGFLOAT_MAX;
		_srcMaxValue = -CGFLOAT_MAX;
		_filters = [NSArray array];
		_target = target;
	}
	return self;
}

- (instancetype)init
{
	return[self initWithTarget:nil];
}

- (const CGFloat *)sourceMinValue { return (_srcMinValue != +CGFLOAT_MAX) ? &_srcMinValue : nil; }
- (const CGFloat *)sourceMaxValue { return (_srcMaxValue != -CGFLOAT_MAX) ? &_srcMaxValue : nil; }

- (void)addSourceValue:(CGFloat)value update:(BOOL)update
{
	BOOL needsUpdate = NO;
	if(_srcMinValue > value) {
		_srcMinValue = value;
		needsUpdate |= update;
	}
	if(_srcMaxValue < value) {
		_srcMaxValue = value;
		needsUpdate |= update;
	}
	if(needsUpdate) {
		[self updateTarget];
	}
}

- (void)clearSourceValues:(BOOL)update
{
	_srcMinValue = +CGFLOAT_MAX;
	_srcMaxValue = -CGFLOAT_MAX;
}

- (void)addFilterToLast:(id<FMRangeFilter>)object
{
	@synchronized(self) {
		if(![_filters containsObject:object]) {
			_filters = [_filters arrayByAddingObject:object];
		}
	}
}

- (void)addFilterToFirst:(id<FMRangeFilter>)object
{
    @synchronized(self) {
        if(![_filters containsObject:object]) {
            NSMutableArray *ar = _filters.mutableCopy;
            [ar insertObject:object atIndex:0];
            _filters = ar.copy;
        }
    }
}

- (void)removeFilter:(id<FMRangeFilter>)object
{
	@synchronized(self) {
		if([_filters containsObject:object]) {
			NSMutableArray *newRestrictions = [_filters mutableCopy];
			[newRestrictions removeObject:object];
			_filters = [newRestrictions copy];
		}
	}
}

- (void)replaceFilter:(id<FMRangeFilter>)oldRestriction
		   withFilter:(id<FMRangeFilter>)newRestriction
{
	@synchronized(self) {
		if([_filters containsObject:oldRestriction]) {
			NSMutableArray *newRestrictions = [_filters mutableCopy];
			NSUInteger idx = [newRestrictions indexOfObject:oldRestriction];
			[newRestrictions replaceObjectAtIndex:idx withObject:newRestriction];
			_filters = [newRestrictions copy];
		}
	}
}

- (void)updateTarget
{
	FMDimensionalProjection *projection = _target;
	if(projection) {
		NSArray<id<FMRangeFilter>> *restrictions = _filters;
		CGFloat min = +CGFLOAT_MAX;
		CGFloat max = -CGFLOAT_MAX;
		for(id<FMRangeFilter> restriction in restrictions.objectEnumerator) {
			[restriction updater:self minValue:&min maxValue:&max];
		}
		
		[projection setMin:min max:max];
	}
}

@end
