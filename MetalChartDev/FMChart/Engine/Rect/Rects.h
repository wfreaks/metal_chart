//
//  Rects.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/26.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Protocols.h"
#import "Prototypes.h"


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
@property (readonly, nonatomic) FMUniformBarConfiguration * _Nonnull conf;

- (id<FMSeries> _Nullable)series;

@end

@interface FMOrderedBarPrimitive : FMBarPrimitive

@property (strong, nonatomic) FMOrderedSeries * _Nullable series;
@property (readonly, nonatomic) FMUniformBarAttributes * _Nonnull attributes;

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
								 series:(FMOrderedSeries * _Nullable)series
						  configuration:(FMUniformBarConfiguration * _Nullable)conf
							 attributes:(FMUniformBarAttributes * _Nullable)attr
;

@end

@interface FMOrderedAttributedBarPrimitive : FMBarPrimitive

@property (strong, nonatomic) FMOrderedAttributedSeries * _Nullable series;
@property (strong, nonatomic) FMUniformBarAttributesArray * _Nonnull attributesArray;

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
								 series:(FMOrderedAttributedSeries * _Nullable)series
						  configuration:(FMUniformBarConfiguration * _Nullable)conf
						attributesArray:(FMUniformBarAttributesArray * _Nullable)attrs
			 attributesCapacityOnCreate:(NSUInteger)capacity
;

@end
