//
//  PointBuffers.m
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/27.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "PointBuffers.h"
#import <Metal/Metal.h>
#import "DeviceResource.h"

@implementation FMUniformPointAttributes

- (instancetype)initWithResource:(FMDeviceResource *)resource
{
	self = [super initWithResource:resource size:sizeof(uniform_point_attr)];
	if(self) {
		[self setInnerRadius:5];
		[self setOuterRadius:6];
		[self setInnerColorRed:0.1 green:0.5 blue:0.8 alpha:0.6];
		[self setOuterColorRed:0.1 green:0.3 blue:0.5 alpha:1.0];
	}
	return self;
}

- (uniform_point_attr *)point { return ((uniform_point_attr *)([self.buffer contents])) + self.index; }

- (void)setInnerColorRed:(float)r green:(float)g blue:(float)b alpha:(float)a
{
	self.point->color_inner = vector4(r,g,b,a);
}

- (void)setInnerColorRef:(vector_float4 const *)color
{
	self.point->color_inner = *color;
}

- (void)setInnerColor:(vector_float4)color
{
	self.point->color_inner = color;
}

- (void)setOuterColorRed:(float)r green:(float)g blue:(float)b alpha:(float)a
{
	self.point->color_outer = vector4(r,g,b,a);
}

- (void)setOuterColorRef:(vector_float4 const *)color
{
	self.point->color_outer = *color;
}

- (void)setOuterColor:(vector_float4)color
{
	self.point->color_outer = color;
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


@implementation FMUniformPointAttributesArray

- (instancetype)initWithResource:(FMDeviceResource *)resource capacity:(NSUInteger)capacity
{
	auto ptr = std::make_shared<MTLObjectBuffer<uniform_point_attr>>(resource.device, capacity);
	self = [super initWithBuffer:std::static_pointer_cast<MTLObjectBufferBase>(ptr)];
	return self;
}

+ (Class)attributesClass { return [FMUniformPointAttributes class]; }

@end

