//
//  CircleBuffers.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/11/18.
//  Copyright © 2015 Keisuke Mori. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import "circle_shared.h"
#import "Prototypes.h"

@protocol MTLBuffer;
@class UIColor;

/**
 * FMUniformArcConfiguration represents configurations applied to all data points when drawn using FMArcPrimitive.
 * If conflicting attributes are supplied by indivisual data, then attributes of specified by data will be used.
 */

@interface FMUniformArcConfiguration : NSObject

@property (nonatomic, readonly) id<MTLBuffer> _Nonnull buffer;
@property (nonatomic, readonly) uniform_arc_configuration * _Nonnull conf;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init
UNAVAILABLE_ATTRIBUTE;

- (void)setInnerRadius:(float)radius;
- (void)setOuterRadius:(float)radius;
- (void)setRadiusInner:(float)inner outer:(float)outer;
- (void)setRadianOffset:(float)radian;

/**
 * a scaling factor that will be applied to radius components of all data.
 */
 
- (void)setRadianScale:(float)scale;

@end


/**
 * A wrapper class for struct arc_attrs that provide setter methods.
 * Interpretations for Inner/outer radius and colors are equivalent to FMUniformArcConfiguration.
 */

@interface FMUniformArcAttributes : NSObject

@property (nonatomic, readonly) uniform_arc_attributes * _Nonnull attr;

- (instancetype _Nonnull)init
UNAVAILABLE_ATTRIBUTE;

- (void)setInnerRadius:(float)radius;
- (void)setOuterRadius:(float)radius;
- (void)setRadiusInner:(float)inner outer:(float)outer;
- (void)setColor:(UIColor *_Nonnull)color;
- (void)setColorVec:(vector_float4)color;
- (void)setColorVecRef:(const vector_float4 *_Nonnull)color;
- (void)setColorRed:(float)r green:(float)g blue:(float)b alpha:(float)a;

@end


/**
 * See FMAttribuesArray, FMArrayBuffer and FMUniformArcAttributes for details.
 */

@interface FMUniformArcAttributesArray : NSObject

@property (nonatomic, readonly) id<MTLBuffer> _Nonnull buffer;
@property (nonatomic, readonly) NSArray<FMUniformArcAttributes*> * _Nonnull array;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
								 capacity:(NSUInteger)capacity
;

- (instancetype _Nonnull)init
UNAVAILABLE_ATTRIBUTE;

- (FMUniformArcAttributes * _Nonnull)objectAtIndexedSubscript:(NSUInteger)index;

@end

