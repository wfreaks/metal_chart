//
//  FMProjections.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/11/17.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import "FMMetalChart.h"

/**
 * FMDimensionalProjection defines an element of FMProjectionCartesian2D.
 * It represents an source(data) range of 1-dimensional mapping.
 * mid and length are calculated properties from min/max.
 */

@interface FMDimensionalProjection : NSObject

@property (readonly, nonatomic) NSInteger dimensionId;
@property (assign  , nonatomic) CGFloat	 min;
@property (assign  , nonatomic) CGFloat	 max;
@property (readonly, nonatomic) CGFloat	 mid;
@property (readonly, nonatomic) CGFloat	 length;

- (instancetype _Nonnull)initWithDimensionId:(NSInteger)dimId
									minValue:(CGFloat)min
									maxValue:(CGFloat)max
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

- (void)setMin:(CGFloat)min max:(CGFloat)max;

/**
 * converts a given value to that of another FMDimensinalProjection instance using view coordinates system,
 * assuming that the given instance shares a same view and a dimension index (x/y).
 */
- (CGFloat)convertValue:(CGFloat)value
					 to:(FMDimensionalProjection * _Nonnull)to
;

@end


/**
 * FMProjectionCartesian2D is a fundamental class that implements FMProjection protocol and represents a mapping from a 2-dimensional cartesian space to a view space.
 * A instance of this class has an gpu buffer internally, and writes mapping data into it when the method defined by FMProjection protocol called.
 * Be aware of difference between dimension id (identifier) and dimension index (x/y).
 */

@interface FMProjectionCartesian2D : NSObject<FMProjection>

@property (readonly, nonatomic) FMDimensionalProjection * _Nonnull dimX;
@property (readonly, nonatomic) FMDimensionalProjection * _Nonnull dimY;
@property (readonly, nonatomic) FMUniformProjectionCartesian2D * _Nonnull projection;
@property (readonly, nonatomic) NSArray<FMDimensionalProjection *> * _Nonnull dimensions;

@property (nonatomic, readonly) NSString * _Nonnull key;

- (instancetype _Nonnull)initWithDimensionX:(FMDimensionalProjection * _Nonnull)x
										  Y:(FMDimensionalProjection * _Nonnull)y
								   resource:(FMDeviceResource *_Nullable)resource
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

/**
 * returns dimension with given dimension id if exists.
 */
- (FMDimensionalProjection * _Nullable)dimensionWithId:(NSInteger)dimensionId;

/**
 * return if given list of dimension ids matches to that of dimensions property.
 */
- (BOOL)matchesDimensionIds:(NSArray<NSNumber*> * _Nonnull)ids;

@end


/**
 * FMProjectionPolar is an implementation of FMProjection protocol which represents mapping from a poloar coordinate system to a view coordinate system.
 * An insatnce of this class does not provide any methods to configure a backing gpu buffer object currently.
 * (may be implemented in future, if neccessary.)
 */

@interface FMProjectionPolar : NSObject<FMProjection>

@property (nonatomic, readonly) FMUniformProjectionPolar * _Nonnull projection;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nullable)resource
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init
UNAVAILABLE_ATTRIBUTE;

@end


