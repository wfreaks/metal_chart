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

@implementation UniformPlotRectAttributes

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

- (void)setCornerRadius:(float)lt rt:(float)rt lb:(float)lb rb:(float)rb
{
    self.rect->corner_radius = vector4(lt, rt, lb, rb);
}

- (void)setCornerRadius:(float)radius
{
    self.rect->corner_radius = vector4(radius, radius, radius, radius);
}

@end


@implementation UniformBarAttributes

@dynamic bar;

- (instancetype)initWithResource:(DeviceResource *)resource
{
    self = [super init];
    if(self) {
        _buffer = [resource.device newBufferWithLength:sizeof(uniform_bar) options:MTLResourceOptionCPUCacheModeWriteCombined];
        [self setBarWidth:3];
        [self setBarDirection:CGPointMake(0, 1)];
        [self setColor:0.4 green:0.4 blue:0.4 alpha:0.6];
    }
    return self;
}

- (uniform_bar *)bar
{
    return (uniform_bar *)([_buffer contents]);
}

- (void)setColor:(float)red green:(float)green blue:(float)blue alpha:(float)alpha
{
    self.bar->color = vector4(red, green, blue, alpha);
}

- (void)setCornerRadius:(float)lt rt:(float)rt lb:(float)lb rb:(float)rb
{
    self.bar->corner_radius = vector4(lt, rt, lb, rb);
}

- (void)setCornerRadius:(float)radius
{
    self.bar->corner_radius = vector4(radius, radius, radius, radius);
}

- (void)setBarWidth:(float)width
{
    self.bar->width = width;
}

- (void)setAnchorPoint:(CGPoint)point
{
    self.bar->anchor_point = vector2((float)point.x, (float)point.y);
}

- (void)setBarDirection:(CGPoint)dir

{
    self.bar->dir = vector2((float)dir.x, (float)dir.y);
}

@end




