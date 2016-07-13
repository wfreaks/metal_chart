//
//  Circles.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/11/18.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Protocols.h"
#import "Prototypes.h"

@interface FMArcPrimitive : NSObject

@property (nonatomic, readonly) FMEngine * _Nonnull engine;
@property (nonatomic, readonly) FMUniformArcConfiguration * _Nonnull configuration;
@property (nonatomic, readonly) FMUniformArcAttributesArray * _Nonnull attributes;

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
						  configuration:(FMUniformArcConfiguration * _Nullable)conf
							 attributes:(FMUniformArcAttributesArray * _Nullable)attr
					 attributesCapacity:(NSUInteger)capacity
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init
UNAVAILABLE_ATTRIBUTE;

- (void)encodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
		projection:(FMUniformProjectionPolar * _Nonnull)projection
			values:(FMIndexedFloatBuffer * _Nonnull)values
			offset:(NSUInteger)offset
			 count:(NSUInteger)count
;

@end

/**
 * Presents data (θ1, θ2, θ3, θ4) as an series of arc ([0,θ1], [θ1, θ2], [θ2, θ3], [θ3, θ4])
 * with the specified (inner/outer) radius and colors. if the order of series θn is not coherent, rendering results are undefined.
 *
 * All angular values are treated as radian.
 * This class does not provide any way of sorting or normalizing data.
 */

@interface FMContinuosArcPrimitive : FMArcPrimitive

@end
