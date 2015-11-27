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
        _buffer = [resource.device newBufferWithLength:sizeof(uniform_bar) options:MTLResourceOptionCPUCacheModeWriteCombined];
        [self setBarWidth:3];
        [self setBarDirection:CGPointMake(0, 1)];
        [self setColorRed:0.4 green:0.4 blue:0.4 alpha:0.6];
    }
    return self;
}

- (uniform_bar *)bar
{
    return (uniform_bar *)([_buffer contents]);
}

- (void)setColorRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha
{
    self.bar->color = vector4(red, green, blue, alpha);
}

- (void)setColorRef:(vector_float4 const *)color
{
    self.bar->color = *color;
}

- (void)setColor:(vector_float4)color
{
	self.bar->color = color;
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

- (void)setDepthValue:(float)value
{
    self.bar->depth_value = value;
}

@end



@interface FMUniformRectAttributes()

- (instancetype)initWithPointer:(uniform_rect_attr *)ptr;

@end
@implementation FMUniformRectAttributes

- (instancetype)initWithPointer:(uniform_rect_attr *)ptr
{
	self = [super init];
	if(self) {
		_attr = ptr;
	}
	return self;
}

- (void)setColor:(vector_float4)color { self.attr->color = color; }
- (void)setColorRef:(const vector_float4 *)color { self.attr->color = *color; }

- (void)setColorRed:(float)r green:(float)g blue:(float)b alpha:(float)a
{
	self.attr->color = vector4(r, g, b, a);
}

@end





@implementation FMUniformRectAttributesArray

- (instancetype)initWithResource:(FMDeviceResource *)resource
						capacity:(NSUInteger)capacity
{
	self = [super init];
	if(self) {
		const NSInteger size = sizeof(uniform_rect_attr) * capacity;
		const MTLResourceOptions opt = MTLResourceOptionCPUCacheModeWriteCombined;
		_buffer = [resource.device newBufferWithLength:size
											   options:opt];
		uniform_rect_attr *ptr = (uniform_rect_attr *)[_buffer contents];
		NSMutableArray *array = [NSMutableArray arrayWithCapacity:capacity];
		for(NSUInteger i = 0; i < capacity; ++i) {
			[array addObject:[[FMUniformRectAttributes alloc] initWithPointer:(ptr+i)]];
		}
		_array = array.copy;
	}
	return self;
}

- (FMUniformRectAttributes *)objectAtIndexedSubscript:(NSUInteger)index
{
	return _array[index];
}

@end



