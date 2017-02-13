//
//  RectBuffers.m
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/26.
//  Copyright © 2015 Keisuke Mori. All rights reserved.
//

#import "RectBuffers.h"
#import <Metal/Metal.h>
#import "DeviceResource.h"
#import "UIColor+Utility.h"


@implementation NSValue (FMRectCornerRadius)

+ (instancetype)valueWithCornerRadius:(FMRectCornerRadius)radius
{
	return [self valueWithBytes:&radius objCType:@encode(FMRectCornerRadius)];
}

- (FMRectCornerRadius)FMRectCornerRadiusValue
{
	FMRectCornerRadius radius;
	[self getValue:&radius];
	return radius;
}

@end


@implementation FMUniformPlotRectAttributes

@dynamic rect;

- (instancetype)initWithResource:(FMDeviceResource *)resource
{
	self = [super init];
	if(self) {
		_buffer = [resource.device newBufferWithLength:sizeof(uniform_plot_rect) options:MTLResourceOptionCPUCacheModeWriteCombined];
		[self setCornerRadius:0];
	}
	return self;
}

- (uniform_plot_rect *)rect
{
	return (uniform_plot_rect *)([_buffer contents]);
}

- (void)setColorVec:(vector_float4)color
{
	self.rect->color_start = color;
	self.rect->color_end = color;
	self.rect->pos_start = vector2(1.0f, 0.0f);
	self.rect->pos_start = vector2(1.0f, 0.0f);
}

- (void)setStartColor:(vector_float4)startColor position:(CGPoint)startPosition endColor:(vector_float4)endColor position:(CGPoint)endPosition
{
	self.rect->color_start = startColor;
	self.rect->color_end = endColor;
	self.rect->pos_start = VectFromPoint(startPosition);
	self.rect->pos_end = VectFromPoint(endPosition);
}

- (void)setCornerRadius:(float)radius
{
	self.rect->corner_radius = radius;
	_roundEnabled = (radius > 0);
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
		[self setColorVec:VectFromColor(0.4, 0.4, 0.4, 0.6)];
	}
	return self;
}

- (uniform_bar_attr *)attr
{
	return ((uniform_bar_attr *)([self.buffer contents]) + self.index);
}

- (void)setColorVec:(vector_float4)color
{
	self.attr->color = color;
}

- (void)setCornerRadius:(float)lt rt:(float)rt lb:(float)lb rb:(float)rb
{
	self.attr->corner_radius = vector4(lt, rt, lb, rb);
}

- (void)setCornerRadius:(FMRectCornerRadius)radius
{
	self.attr->corner_radius = vector4(radius.lt, radius.rt, radius.lb, radius.rb);
}

- (void)setAllCornerRadius:(float)radius
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



