//
//  Points.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/27.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Protocols.h"
#import "Prototypes.h"

@interface FMPointPrimitive : NSObject<FMPrimitive>

@property (readonly, nonatomic) FMEngine * _Nonnull engine;

- (id<FMSeries> _Nullable)series;

@end


@interface FMOrderedPointPrimitive : FMPointPrimitive

@property (readonly, nonatomic) FMUniformPointAttributes * _Nonnull attributes;
@property (strong, nonatomic) FMOrderedSeries * _Nullable series;

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
								 series:(FMOrderedSeries * _Nullable)series
							 attributes:(FMUniformPointAttributes * _Nullable)attributes
;
@end


@interface FMOrderedAttributedPointPrimitive : FMPointPrimitive

@property (readonly, nonatomic) FMUniformPointAttributesArray * _Nonnull attributesArray;
@property (strong, nonatomic) FMOrderedAttributedSeries * _Nullable series;

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
								 series:(FMOrderedAttributedSeries * _Nullable)series
					 attributesCapacity:(NSUInteger)capacity
;
@end

