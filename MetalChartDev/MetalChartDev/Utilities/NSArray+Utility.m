//
//  NSArray+Utility.m
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/22.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "NSArray+Utility.h"

@implementation NSArray (Utility)

- (instancetype)arrayByAddingObjectIfNotExists:(id)object
{
	return ([self containsObject:object]) ? self : [self arrayByAddingObject:object];
}

- (instancetype)arrayByRemovingObject:(id)object
{
	if([self containsObject:object]) {
		NSMutableArray *ar = [self mutableCopy];
		[ar removeObject:object];
		return [ar copy];
	}
	return self;
}

- (instancetype)arrayByRemovingObjectAtIndex:(NSUInteger)index
{
	if(self.count > index) {
		NSMutableArray *ar = [self mutableCopy];
		[ar removeObjectAtIndex:index];
		return [ar copy];
	}
	return self;
}

@end

