//
//  MCProjectionUpdater.m
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/10.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "MCProjectionUpdater.h"

@interface MCProjectionUpdater()

@property (readonly, nonatomic) CGFloat initialMin;
@property (readonly, nonatomic) CGFloat initialMax;

@end

@implementation MCProjectionUpdater

- (instancetype)initWithInitialSourceMin:(CGFloat)min max:(CGFloat)max
{
	self = [super self];
	if(self) {
		_initialMin = min;
		_initialMax = max;
		_sourceMinValue = min;
		_sourceMaxValue = max;
		_restrictions = [NSArray array];
	}
	return self;
}

- (void)addSourceValue:(CGFloat)value update:(BOOL)update
{
}

- (void)clearSourceValues:(BOOL)update
{
	_sourceMinValue = _initialMin;
	_sourceMaxValue = _initialMax;
}

- (void)addRestriction:(id<MCRestriction>)object
{
	@synchronized(self) {
		if(![_restrictions containsObject:object]) {
			_restrictions = [_restrictions arrayByAddingObject:object];
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
	NSArray<id<MCRestriction>> *restrictions = _restrictions;
	CGFloat min = CGFLOAT_MAX;
	CGFloat max = CGFLOAT_MIN;
	for(id<MCRestriction> restriction in restrictions) {
		[restriction updater:self minValue:&min maxValue:&max];
	}
	
	MCDimensionalProjection *projection = _target;
	if(projection) {
		projection.min = min;
		projection.max = max;
	}
}

@end
