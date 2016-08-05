//
//  PointBuffers.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/27.
//  Copyright © 2015 Keisuke Mori. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Point_common.h"
#import "Buffers.h"
#import "Prototypes.h"

@protocol MTLBuffer;

/**
 * FMUniformPointAttributes is a wrapper class for uniform_point_attr that provides setter methods.
 * Inner/outer radius and colors are configurable.
 * vector_float4 colors are in RGBA order.
 * behavior is undefined if (innerRadius > outRadius || innerRadius < 0 || outerRadius < 0).
 */

@interface FMUniformPointAttributes : FMAttributesBuffer

@property (readonly, nonatomic) uniform_point_attr * _Nonnull point;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
									 size:(NSUInteger)size
UNAVAILABLE_ATTRIBUTE;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource;

- (void)setInnerColor:(UIColor *_Nonnull)color;
- (void)setInnerColorVec:(vector_float4)color;
- (void)setInnerColorVecRef:(const vector_float4 *_Nonnull)color;
- (void)setInnerColorRed:(float)r green:(float)g blue:(float)b alpha:(float)a;

- (void)setOuterColor:(UIColor *_Nonnull)color;
- (void)setOuterColorVec:(vector_float4)color;
- (void)setOuterColorVecRef:(const vector_float4 *_Nonnull)color;
- (void)setOuterColorRed:(float)r green:(float)g blue:(float)b alpha:(float)a;

- (void)setInnerRadius:(float)r;
- (void)setOuterRadius:(float)r;

@end

/**
 * See FMAttribuesArray, FMArrayBuffer and FMUniformPointAttributes for details.
 */

@interface FMUniformPointAttributesArray : FMAttributesArray<FMUniformPointAttributes*>

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
                                 capacity:(NSUInteger)capacity
NS_DESIGNATED_INITIALIZER;

@end
