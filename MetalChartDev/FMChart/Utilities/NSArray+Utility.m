//
//  NSArray+Utility.m
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/22.
//  Copyright © 2015 Keisuke Mori. All rights reserved.
//

#import "NSArray+Utility.h"

@implementation NSArray (Utility)

- (instancetype)arrayByAddingObjectIfNotExists:(id)object
{
	return ([self containsObject:object]) ? self : [self arrayByAddingObject:object];
}

- (instancetype)arrayByInsertingObjectIfNotExists:(id)object atIndex:(NSUInteger)index
{
	if([self containsObject:object]) return self;
	NSMutableArray *ar = self.mutableCopy;
	[ar insertObject:object atIndex:index];
	return ar;
}

- (instancetype)arrayByRemovingObject:(id)object
{
	if([self containsObject:object]) {
		NSMutableArray *ar = [self mutableCopy];
		[ar removeObject:object];
		return ar;
	}
	return self;
}

- (instancetype)arrayByRemovingObjectAtIndex:(NSUInteger)index
{
	if(self.count > index) {
		NSMutableArray *ar = [self mutableCopy];
		[ar removeObjectAtIndex:index];
		return ar;
	}
	return self;
}

@end




@implementation NSOrderedSet (Utility)

- (instancetype)orderedSetByAddingObject:(id)object
{
	if(![self containsObject:object]) {
		NSMutableOrderedSet *set = [self mutableCopy];
		[set addObject:object];
		return set;
	}
	return self;
}

- (instancetype)orderedSetByRemovingObject:(id)object
{
	if([self containsObject:object]) {
		NSMutableOrderedSet *set = [self mutableCopy];
		[set removeObject:object];
		return set;
	}
	return self;
}

@end



