//
//  RectBuffers.m
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/26.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "RectBuffers.h"
#import <Metal/Metal.h>
#import "DeviceResource.h"

@implementation UniformPlotRect

@dynamic rect;

- (instancetype)initWithResource:(DeviceResource *)resource
{
    self = [super init];
    if(self) {
        _buffer = [resource.device newBufferWithLength:sizeof(uniform_plot_rect) options:MTLResourceOptionCPUCacheModeWriteCombined];
    }
    return self;
}

- (uniform_plot_rect *)rect
{
    return (uniform_plot_rect *)([_buffer contents]);
}

- (void)setColor:(float)red green:(float)green blue:(float)blue alpha:(float)alpha
{
    self.rect->color = vector4(red, green, blue, alpha);
}

- (void)setCornerRadius:(float)lt rt:(float)rt bl:(float)bl br:(float)br
{
    self.rect->corner_radius = vector4(lt, rt, bl, br);
}

@end
