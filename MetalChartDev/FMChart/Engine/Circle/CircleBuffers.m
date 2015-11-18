//
//  CircleBuffers.m
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/11/18.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "CircleBuffers.h"
#import "DeviceResource.h"

@implementation FMUniformArcConfiguration

- (instancetype)initWithResource:(FMDeviceResource *)resource
{
	self = [super init];
	if(self) {
		_buffer = [resource.device newBufferWithLength:sizeof(uniform_arc_configuration)
											   options:MTLResourceOptionCPUCacheModeWriteCombined];
	}
	return self;
}

- (uniform_arc_configuration *)conf { return ((uniform_arc_configuration *)[_buffer contents]); }

- (void)setInnerRadius:(CGFloat)radius { self.conf->radius_inner = radius; }
- (void)setOuterRadius:(CGFloat)radius { self.conf->radius_outer = radius; }
- (void)setRadianOffset:(CGFloat)radian { self.conf->radian_offset = radian; }
- (void)setRadiusInner:(CGFloat)inner outer:(CGFloat)outer
{
	self.conf->radius_inner = inner;
	self.conf->radius_outer = outer;
}

@end





@interface FMUniformArcAttributes()

- (instancetype)initWithPointer:(uniform_arc_attributes *)ptr;

@end
@implementation FMUniformArcAttributes

- (instancetype)initWithPointer:(uniform_arc_attributes *)ptr
{
	self = [super init];
	if(self) {
		_attr = ptr;
	}
	return self;
}

- (void)setInnerRadius:(CGFloat)radius { self.attr->radius_inner = radius; }
- (void)setOuterRadius:(CGFloat)radius { self.attr->radius_outer = radius; }
- (void)setRadiusInner:(CGFloat)inner outer:(CGFloat)outer
{
	self.attr->radius_inner = inner;
	self.attr->radius_outer = outer;
}


- (void)setColor:(vector_float4)color { self.attr->color = color; }
- (void)setColorRef:(const vector_float4 *)color { self.attr->color = *color; }

- (void)setColorRed:(float)r green:(float)g blue:(float)b alpha:(float)a
{
	self.attr->color = vector4(r, g, b, a);
}

@end





@implementation FMUniformArcAttributesArray

- (instancetype)initWithResource:(FMDeviceResource *)resource
						capacity:(NSUInteger)capacity
{
	self = [super init];
	if(self) {
		const NSInteger size = sizeof(uniform_arc_attributes) * capacity;
		const MTLResourceOptions opt = MTLResourceOptionCPUCacheModeWriteCombined;
		_buffer = [resource.device newBufferWithLength:size
											   options:opt];
		uniform_arc_attributes *ptr = (uniform_arc_attributes *)[_buffer contents];
		NSMutableArray *array = [NSMutableArray arrayWithCapacity:capacity];
		for(NSUInteger i = 0; i < capacity; ++i) {
			[array addObject:[[FMUniformArcAttributes alloc] initWithPointer:(ptr+i)]];
		}
		_array = array.copy;
	}
	return self;
}

- (FMUniformArcAttributes *)objectAtIndexedSubscript:(NSUInteger)index
{
	return _array[index];
}

@end



