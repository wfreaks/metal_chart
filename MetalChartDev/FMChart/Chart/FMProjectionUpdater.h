//
//  FMProjectionUpdater.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/10.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>

@protocol FMRangeFilter;
@class FMDimensionalProjection;

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

