//
//  PointBuffers.m
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/08/27.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "PointBuffers.h"
#import <Metal/Metal.h>
#import "DeviceResource.h"

@implementation UniformPoint

@dynamic point;

- (instancetype)initWithResource:(DeviceResource *)resource
{
    self = [super init];
    if(self) {
        _buffer = [resource.device newBufferWithLength:sizeof(uniform_point) options:MTLResourceOptionCPUCacheModeWriteCombined];
        [self setInnerRadius:5];
        [self setOuterRadius:6];
        [self setInnerColor:0.1 green:0.5 blue:0.8 alpha:0.6];
        [self setOuterColor:0.1 green:0.3 blue:0.5 alpha:1.0];
    }
    return self;
}

- (uniform_point *)point { return (uniform_point *)([_buffer contents]); }

- (void)setInnerColor:(float)r green:(float)g blue:(float)b alpha:(float)a
{
    self.point->color_inner = vector4(r,g,b,a);
}

- (void)setOuterColor:(float)r green:(float)g blue:(float)b alpha:(float)a
{
    self.point->color_outer = vector4(r,g,b,a);
}

- (void)setInnerRadius:(float)r
{
    self.point->rad_inner = r;
}

- (void)setOuterRadius:(float)r
{
    self.point->rad_outer = r;
}

@end

