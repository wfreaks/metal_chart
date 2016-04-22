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


@interface FMUniformBarAttributes()

@property (nonatomic, readonly) NSInteger index;

@end
@implementation FMUniformBarAttributes

- (instancetype)initWithResource:(FMDeviceResource *)resource
{
	self = [super init];
	if(self) {
		_buffer = [resource.device newBufferWithLength:sizeof(uniform_bar_attr) options:MTLResourceOptionCPUCacheModeWriteCombined];
		_index = 0;
		[self setBarWidth:3];
		[self setColorRed:0.4 green:0.4 blue:0.4 alpha:0.6];
	}
	return self;
}

- (instancetype)initWithBuffer:(id<MTLBuffer>)buffer index:(NSInteger)index
{
	self = [super init];
	if(self) {
		_buffer = buffer;
		_index = index;
	}
	return self;
}

- (uniform_bar_attr *)attr
{
	return ((uniform_bar_attr *)([_buffer contents]) + _index);
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
	if(self) {
		_array = [self.class createArrayWithBuffer:self.buffer capacity:capacity];
	}
	return self;
}

- (FMUniformBarAttributes *)objectAtIndexedSubscript:(NSUInteger)index
{
	return _array[index];
}

+ (NSArray<FMUniformBarAttributes*>*)createArrayWithBuffer:(id<MTLBuffer>)buffer capacity:(NSUInteger)capacity
{
	NSMutableArray<FMUniformBarAttributes*>* array = [NSMutableArray arrayWithCapacity:capacity];
	for(NSInteger i = 0; i < capacity; ++i) {
		[array addObject:[[FMUniformBarAttributes alloc] initWithBuffer:buffer index:capacity]];
	}
	return [NSArray arrayWithArray:array];
}

- (void)reserve:(NSUInteger)capacity
{
	if(capacity > self.capacity) {
		[super reserve:capacity];
		_array = [self.class createArrayWithBuffer:self.buffer capacity:capacity];
	}
}

@end



