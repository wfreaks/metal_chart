//
//  PointBuffers.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/27.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Point_common.h"
#import "Buffers.h"
#import "Prototypes.h"

@protocol MTLBuffer;

@interface FMUniformPointAttributes : NSObject

@property (readonly, nonatomic) id<MTLBuffer> _Nonnull buffer;
@property (readonly, nonatomic) uniform_point * _Nonnull point;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource;

- (void)setInnerColorRed:(float)r green:(float)g blue:(float)b alpha:(float)a;
- (void)setInnerColor:(vector_float4)color;
- (void)setInnerColorRef:(vector_float4 const * _Nonnull)color;
- (void)setOuterColorRed:(float)r green:(float)g blue:(float)b alpha:(float)a;
- (void)setOuterColor:(vector_float4)color;
- (void)setOuterColorRef:(vector_float4 const * _Nonnull)color;

- (void)setInnerRadius:(float)r;
- (void)setOuterRadius:(float)r;

@end


@interface FMUniformPointAttributesArray : FMArrayBuffer

@property (nonatomic, readonly) NSArray<FMUniformPointAttributes*>* _Nonnull array;

- (instancetype _Nonnull)initWithBuffer:(id<MTLBuffer> _Nonnull)buffer
UNAVAILABLE_ATTRIBUTE;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
                                 capacity:(NSUInteger)capacity
NS_DESIGNATED_INITIALIZER;

@end
