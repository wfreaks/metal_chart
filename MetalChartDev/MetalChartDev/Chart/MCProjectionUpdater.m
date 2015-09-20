//
//  MCProjectionUpdater.m
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/10.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "MCProjectionUpdater.h"
#import "MCRestrictions.h"

@interface MCProjectionUpdater()

@property (assign, nonatomic) CGFloat srcMinValue;
@property (assign, nonatomic) CGFloat srcMaxValue;

@end

@implementation MCProjectionUpdater

- (instancetype)initWithTarget:(MCDimensionalProjection * _Nullable)target
{
	self = [super self];
	if(self) {
		_srcMinValue = +CGFLOAT_MAX;
		_srcMaxValue = -CGFLOAT_MAX;
		_restrictions = [NSArray array];
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

- (void)addRestrictionToLast:(id<MCRestriction>)object
{
	@synchronized(self) {
		if(![_restrictions containsObject:object]) {
			_restrictions = [_restrictions arrayByAddingObject:object];
		}
	}
}

- (void)addRestrictionToFirst:(id<MCRestriction>)object
{
    @synchronized(self) {
        if(![_restrictions containsObject:object]) {
            NSMutableArray *ar = _restrictions.mutableCopy;
            [ar insertObject:object atIndex:0];
            _restrictions = ar.copy;
        }
    }
}

- (void)removeRestriction:(id<MCRestriction>)object
{
	@synchronized(self) {
		if([_restrictions containsObject:object]) {
			NSMutableArray *newRestrictions = [_restrictions mutableCopy];
			[newRestrictions removeObject:object];
			_restrictions = [newRestrictions copy];
		}
	}
}

- (void)updateTarget
{
	MCDimensionalProjection *projection = _target;
	if(projection) {
		NSArray<id<MCRestriction>> *restrictions = _restrictions;
		CGFloat min = +CGFLOAT_MAX;
		CGFloat max = -CGFLOAT_MAX;
		for(id<MCRestriction> restriction in restrictions.objectEnumerator) {
			[restriction updater:self minValue:&min maxValue:&max];
		}
		
		[projection setMin:min max:max];
	}
}

@end
