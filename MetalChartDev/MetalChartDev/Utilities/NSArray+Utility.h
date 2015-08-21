//
//  NSArray+Utility.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/22.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Utility)

- (_Nonnull instancetype)arrayByAddingObjectIfNotExists:(id _Nonnull)object;
- (_Nonnull instancetype)arrayByRemovingObject:(id _Nonnull)object;
- (_Nonnull instancetype)arrayByRemovingObjectAtIndex:(NSUInteger)index;

@end

