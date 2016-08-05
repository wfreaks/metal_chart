//
//  Protocols.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/28.
//  Copyright © 2015 Keisuke Mori. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Prototypes.h"

@protocol MTLRenderCommandEncoder;

/**
 * Well this protocol is COMPLETE USELESS so please ignore.
 * But giving the concept of 'primitive' may help you understand the framework.
 *
 * Primitve is a combination of a custom shader, a set of configurable attributes and a wrapper class to integrate them for visualizing given data.
 * A primitive in general does not have references to a projection (FMProjection),
 * and it simplifies the behavior of each visual element and the procedure for visualizing data.
 * 
 * So you can ignore these layers when you implement custom shaders and renderable / attachment objects.
 */

@protocol FMPrimitive <NSObject>

- (void)encodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
		projection:(FMUniformProjectionCartesian2D * _Nonnull)projection
;

@end

