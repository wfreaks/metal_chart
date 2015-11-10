//
//  Points.h
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/08/27.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Protocols.h"

@class FMEngine;
@class FMUniformProjectionCartesian2D;
@class FMUniformPlotRectAttributes;
@class FMUniformPointAttributes;
@class FMOrderedSeries;
@class FMIndexedSeries;

@protocol MTLRenderCommandEncoder;
@protocol Series;

@interface FMPointPrimitive : NSObject<FMPrimitive>

@property (readonly, nonatomic) FMEngine * _Nonnull engine;
@property (readonly, nonatomic) FMUniformPointAttributes * _Nonnull attributes;

- (id<Series> _Nullable)series;

@end

@interface FMOrderedPointPrimitive : FMPointPrimitive

@property (strong, nonatomic) FMOrderedSeries * _Nullable series;

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
                                          series:(FMOrderedSeries * _Nullable)series
									  attributes:(FMUniformPointAttributes * _Nullable)attributes
;
@end

@interface FMIndexedPointPrimitive : FMPointPrimitive

@property (strong, nonatomic) FMIndexedSeries * _Nullable series;

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
										  series:(FMIndexedSeries * _Nullable)series
									  attributes:(FMUniformPointAttributes * _Nullable)attributes
;
@end


@interface FMDynamicPointPrimitive : FMPointPrimitive

@property (strong, nonatomic) id<Series> _Nullable series;

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
										  series:(id<Series> _Nullable)series
									  attributes:(FMUniformPointAttributes * _Nullable)attributes
;
@end

