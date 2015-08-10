//
//  MCProjectionUpdater.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/10.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MetalChart.h"

@class MCProjectionUpdater;

@protocol MCRestriction<NSObject>

- (void)updater:(MCProjectionUpdater * _Nonnull)updater
	   minValue:(CGFloat * _Nonnull)min
	   maxValue:(CGFloat * _Nonnull)max
;

@end

@interface MCProjectionUpdater : NSObject

@property (readonly, nonatomic) CGFloat sourceMinValue;
@property (readonly, nonatomic) CGFloat sourceMaxValue;
@property (readonly, nonatomic) NSArray<id<MCRestriction>> * _Nonnull restrictions;

@property (strong, nonatomic) MCDimensionalProjection * _Nullable target;

- (_Null_unspecified instancetype)initWithInitialSourceMin:(CGFloat)min max:(CGFloat)max;

- (void)addSourceValue:(CGFloat)value update:(BOOL)update;
- (void)clearSourceValues:(BOOL)update;

- (void)addRestriction:(id<MCRestriction> _Nonnull)object;
- (void)removeRestriction:(id<MCRestriction> _Nonnull)object;

- (void)updateTarget;

@end
