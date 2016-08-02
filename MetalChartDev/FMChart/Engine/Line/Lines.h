//
//  PolyLines.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/06.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import "Protocols.h"
#import "Prototypes.h"

/**
 * FMLinePrimitive draws line segments between points of given FMSeries.
 * It can be polyline or separated but currently only polyline are provided.
 * (I implemented separated line primitive, but it wasn's used and it was making shaders harder to maintain)
 */

@interface FMLinePrimitive : NSObject<FMPrimitive>

@property (nonatomic, readonly) FMUniformLineConf * _Nonnull conf;
@property (readonly, nonatomic) FMEngine * _Nonnull engine;

- (id<FMSeries> _Nullable)series;

@end



@interface FMPolyLinePrimitive : FMLinePrimitive

@end


/**
 * Draws a polyline defined by given FMOrderedSeries in order,
 * with a single set of visual attributes.
 * It also draws points (circles) on the joints if given the point attributes.
 */

@interface FMOrderedPolyLinePrimitive : FMPolyLinePrimitive

@property (nonatomic) FMUniformLineAttributes * _Nonnull attributes;
@property (nonatomic) FMUniformPointAttributes * _Nullable pointAttributes;
@property (nonatomic) FMOrderedSeries * _Nullable series;

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
								   orderedSeries:(FMOrderedSeries * _Nullable)series
									  attributes:(FMUniformLineAttributes * _Nullable)attributes
;

@end


/**
 * Draws a plyline defined by given FMOrderedAttributedSeries in order,
 * with the attribute sets of the index data specifies.
 * An attribute index of the line segment p1 -> p2 will be the one specified by p1 (p1.idx).
 * 
 * It doest not support drawing point on it. (creating another attributed series and point primitive will be much more flexible)
 */

@interface FMOrderedAttributedPolyLinePrimitive : FMPolyLinePrimitive

@property (nonatomic) FMUniformLineAttributesArray * _Nonnull attributesArray;
@property (nonatomic) FMOrderedAttributedSeries * _Nullable series;

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
						  orderedSeries:(FMOrderedAttributedSeries * _Nullable)series
                     attributesCapacity:(NSUInteger)capacity
;

@end


/**
 * Draws an axis using its configuration and axis/ticks attributes.
 * managing configuration is the responsibility of a wrapper class that implements FMAttachment (FMAxis).
 *
 * See FMUniformAxisConfiguration and FMUniformAxisAttributes for interpretations of their properties.
 */

@interface FMAxisPrimitive : NSObject

@property (readonly, nonatomic) FMUniformAxisConfiguration * _Nonnull configuration;
@property (readonly, nonatomic) FMUniformAxisAttributes * _Nonnull axisAttributes;
@property (readonly, nonatomic) FMUniformAxisAttributes * _Nonnull majorTickAttributes;
@property (readonly, nonatomic) FMUniformAxisAttributes * _Nonnull minorTickAttributes;

@property (readonly, nonatomic) FMEngine * _Nonnull engine;

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
;

- (void)encodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
		projection:(FMUniformProjectionCartesian2D * _Nonnull)projection
;

@end


/**
 * Draws grid line using its attributes and configuration object.
 * Managing attributes and configuration are the responsibility of a wrapper class that implmenents FMAttachment (FMGridLine).
 * 
 * See FMUniformGridAttributes, FMUniformGridConfiguration for interpretations of properties.
 */

@interface FMGridLinePrimitive : NSObject

@property (readonly, nonatomic) FMUniformGridConfiguration * _Nonnull configuration;
@property (readonly, nonatomic) FMUniformGridAttributes * _Nonnull attributes;

@property (readonly, nonatomic) FMEngine * _Nonnull engine;

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

- (void)encodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
		projection:(FMUniformProjectionCartesian2D * _Nonnull)projection
		  maxCount:(NSUInteger)maxCount
;


@end



