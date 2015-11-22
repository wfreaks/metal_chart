//
//  Rects.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/26.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Protocols.h"

@class FMEngine;
@class FMUniformProjectionCartesian2D;
@class FMUniformPlotRectAttributes;
@class FMUniformBarAttributes;
@class FMOrderedSeries;
@class FMOrderedAttributedSeries;

@protocol MTLRenderCommandEncoder;
@protocol FMSeries;

@interface FMPlotRectPrimitive : NSObject

@property (readonly, nonatomic) FMEngine * _Nonnull engine;
@property (readonly, nonatomic) FMUniformPlotRectAttributes * _Nonnull attributes;

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine;

- (void)encodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
        projection:(FMUniformProjectionCartesian2D * _Nonnull)projection
;

@end


@interface FMBarPrimitive : NSObject<FMPrimitive>

@property (readonly, nonatomic) FMEngine * _Nonnull engine;
@property (readonly, nonatomic) FMUniformBarAttributes * _Nonnull attributes;

- (id<FMSeries> _Nullable)series;

@end

@interface FMOrderedBarPrimitive : FMBarPrimitive

@property (strong, nonatomic) FMOrderedSeries * _Nullable series;

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
								 series:(FMOrderedSeries * _Nullable)series
							 attributes:(FMUniformBarAttributes * _Nullable)attributes
;

@end

@interface FMOrderedAttributedBarPrimitive : FMBarPrimitive

@property (strong, nonatomic) FMOrderedAttributedSeries * _Nullable series;

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
								 series:(FMOrderedAttributedSeries * _Nullable)series
							 attributes:(FMUniformBarAttributes * _Nullable)attributes
;

@end
