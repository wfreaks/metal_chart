//
//  RectBuffers.m
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/26.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "RectBuffers.h"
#import <Metal/Metal.h>
#import "DeviceResource.h"



@implementation FMUniformPlotRectAttributes

@dynamic rect;

- (instancetype)initWithResource:(FMDeviceResource *)resource
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

- (void)setColorRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha
{
	self.rect->color = vector4(red, green, blue, alpha);
}

- (void)setColorRef:(vector_float4 const *)color
{
	self.rect->color = *color;
}

- (void)setColor:(vector_float4)color
{
	self.rect->color = color;
}

- (void)setCornerRadius:(float)lt rt:(float)rt lb:(float)lb rb:(float)rb
{
	self.rect->corner_radius = vector4(lt, rt, lb, rb);
}

- (void)setCornerRadius:(float)radius
{
	self.rect->corner_radius = vector4(radius, radius, radius, radius);
}

- (void)setDepthValue:(float)value
{
	self.rect->depth_value = value;
}

@end



@implementation FMUniformBarConfiguration

- (instancetype)initWithResource:(FMDeviceResource *)resource
{
	self = [super init];
	if(self) {
		_buffer = [resource.device newBufferWithLength:sizeof(uniform_bar_conf) options:MTLResourceOptionCPUCacheModeWriteCombined];
		[self setBarDirection:CGPointMake(0, 1)];
	}
	return self;
}

- (uniform_bar_conf *)conf
{
	return (uniform_bar_conf *)([_buffer contents]);
}

- (void)setAnchorPoint:(CGPoint)point
{
	self.conf->anchor_point = vector2((float)point.x, (float)point.y);
}

- (void)setBarDirection:(CGPoint)dir

{
	self.conf->dir = vector2((float)dir.x, (float)dir.y);
}

- (void)setDepthValue:(float)value
{
	self.conf->depth_value = value;
}

@end


@implementation FMUniformBarAttributes

- (instancetype)initWithResource:(FMDeviceResource *)resource
{
	self = [super initWithResource:resource size:sizeof(uniform_bar_attr)];
	if(self) {
		[self setBarWidth:3];
		[self setColorRed:0.4 green:0.4 blue:0.4 alpha:0.6];
	}
	return self;
}

- (uniform_bar_attr *)attr
{
	return ((uniform_bar_attr *)([self.buffer contents]) + self.index);
}

- (void)setColorRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha
{
	self.attr->color = vector4(red, green, blue, alpha);
}

- (void)setColorRef:(vector_float4 const *)color
{
	self.attr->color = *color;
}

- (void)setColor:(vector_float4)color
{
	self.attr->color = color;
}

- (void)setCornerRadius:(float)lt rt:(float)rt lb:(float)lb rb:(float)rb
{
	self.attr->corner_radius = vector4(lt, rt, lb, rb);
}

- (void)setCornerRadius:(float)radius
{
	self.attr->corner_radius = vector4(radius, radius, radius, radius);
}

- (void)setBarWidth:(float)width
{
	self.attr->width = width;
}

@end





@implementation FMUniformBarAttributesArray

- (instancetype)initWithResource:(FMDeviceResource *)resource
						capacity:(NSUInteger)capacity
{
	auto ptr = std::make_shared<MTLObjectBuffer<uniform_bar_attr>>(resource.device, capacity);
	self = [super initWithBuffer:std::static_pointer_cast<MTLObjectBufferBase>(ptr)];
	return self;
}

+ (Class)attributesClass { return [FMUniformBarAttributes class]; }

@end



