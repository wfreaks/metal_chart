//
//  FMProjectionUpdater.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/10.
//  Copyright © 2015 Keisuke Mori. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import "Prototypes.h"

/**
 * FMProjectionUpdater is a utility class for determining min/max properties of FMDimensionalProjection.
 * It is just a utility class, and you can choose not to use it, but default implementations heavily rely on it,
 * since managing visible range (projection) is a critical part of charting.
 *
 * Its usage is very simple :
 * 1. add filters you want.
 * 2. put source values to determine min/max of data.
 * 3. update projection if neccessary (on finishing load, on user interactions, on modifying filters).
 * 4. clear source values if needed, and go back to 1.
 */

@interface FMProjectionUpdater : NSObject

@property (readonly, nonatomic) NSArray<id<FMRangeFilter>> * _Nonnull filters;

@property (strong, nonatomic) FMDimensionalProjection * _Nullable target;

- (instancetype _Nonnull)initWithTarget:(FMDimensionalProjection * _Nullable)target
NS_DESIGNATED_INITIALIZER;

- (const CGFloat * _Nullable)sourceMinValue;
- (const CGFloat * _Nullable)sourceMaxValue;

- (void)addSourceValue:(CGFloat)value update:(BOOL)update;
- (void)clearSourceValues:(BOOL)update;

- (void)addFilterToLast:(id<FMRangeFilter> _Nonnull)object;
- (void)addFilterToFirst:(id<FMRangeFilter> _Nonnull)object;
- (void)removeFilter:(id<FMRangeFilter> _Nonnull)object;
- (void)replaceFilter:(id<FMRangeFilter> _Nonnull)oldRestriction
		   withFilter:(id<FMRangeFilter> _Nonnull)newRestriction;

- (void)updateTarget;

@end

