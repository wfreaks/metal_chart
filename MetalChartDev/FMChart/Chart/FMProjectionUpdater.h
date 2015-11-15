//
//  FMProjectionUpdater.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/10.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MetalChart.h"

@protocol FMRestriction;

@interface FMProjectionUpdater : NSObject

@property (readonly, nonatomic) NSArray<id<FMRestriction>> * _Nonnull restrictions;

@property (strong, nonatomic) FMDimensionalProjection * _Nullable target;

- (instancetype _Nonnull)initWithTarget:(FMDimensionalProjection * _Nullable)target
NS_DESIGNATED_INITIALIZER;

- (const CGFloat * _Nullable)sourceMinValue;
- (const CGFloat * _Nullable)sourceMaxValue;

- (void)addSourceValue:(CGFloat)value update:(BOOL)update;
- (void)clearSourceValues:(BOOL)update;

- (void)addRestrictionToLast:(id<FMRestriction> _Nonnull)object;
- (void)addRestrictionToFirst:(id<FMRestriction> _Nonnull)object;
- (void)removeRestriction:(id<FMRestriction> _Nonnull)object;
- (void)replaceRestriction:(id<FMRestriction> _Nonnull)oldRestriction
		   withRestriction:(id<FMRestriction> _Nonnull)newRestriction;

- (void)updateTarget;

@end

