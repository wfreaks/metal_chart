//
//  PointBuffers.h
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/08/27.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Point_common.h"

@class DeviceResource;
@protocol MTLBuffer;

@interface UniformPoint : NSObject

@property (readonly, nonatomic) id<MTLBuffer> _Nonnull buffer;
@property (readonly, nonatomic) uniform_point * _Nonnull point;

- (instancetype _Nonnull)initWithResource:(DeviceResource * _Nonnull)resource;

- (void)setInnerColor:(float)r green:(float)g blue:(float)b alpha:(float)a;
- (void)setOuterColor:(float)r green:(float)g blue:(float)b alpha:(float)a;

- (void)setInnerRadius:(float)r;
- (void)setOuterRadius:(float)r;

@end
