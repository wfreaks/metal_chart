//
//  FMProjections.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/11/17.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import "MetalChart.h"

@class FMUniformProjectionCartesian2D;
@class FMUniformProjectionPolar;
@class FMDeviceResource;

@interface FMDimensionalProjection : NSObject

@property (readonly, nonatomic) NSInteger dimensionId;
@property (assign  , nonatomic) CGFloat	 min;
@property (assign  , nonatomic) CGFloat	 max;
@property (readonly, nonatomic) CGFloat	 mid;
@property (readonly, nonatomic) CGFloat	 length;
@property (copy	, nonatomic) void (^ _Nullable willUpdate)(CGFloat * _Nullable newMin, CGFloat * _Nullable newMax);

- (instancetype _Nonnull)initWithDimensionId:(NSInteger)dimId
									minValue:(CGFloat)min
									maxValue:(CGFloat)max
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

- (void)setMin:(CGFloat)min max:(CGFloat)max;

// 画面上での位置が重なるような値を算出する.
- (CGFloat)convertValue:(CGFloat)value
					 to:(FMDimensionalProjection * _Nonnull)to
;

@end

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

- (FMDimensionalProjection * _Nullable)dimensionWithId:(NSInteger)dimensionId;

- (BOOL)matchesDimensionIds:(NSArray<NSNumber*> * _Nonnull)ids;

@end


@interface FMProjectionPolar : NSObject<FMProjection>

@property (nonatomic, readonly) FMUniformProjectionPolar * _Nonnull projection;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nullable)resource
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init
UNAVAILABLE_ATTRIBUTE;

@end











