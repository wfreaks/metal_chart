//
//  CircleBuffers.m
//  FMChart
//
//  Created by Keisuke Mori on 2015/11/18.
//  Copyright © 2015 Keisuke Mori. All rights reserved.
//

#import "CircleBuffers.h"
#import "DeviceResource.h"
#import "UIColor+Utility.h"

@implementation FMUniformArcConfiguration

- (instancetype)initWithResource:(FMDeviceResource *)resource
{
	self = [super init];
	if(self) {
		_buffer = [resource.device newBufferWithLength:sizeof(uniform_arc_configuration)
											   options:MTLResourceOptionCPUCacheModeWriteCombined];
		[self setRadianScale:1];
	}
	return self;
}

- (uniform_arc_configuration *)conf { return ((uniform_arc_configuration *)[_buffer contents]); }

- (void)setInnerRadius:(float)radius { self.conf->radius_inner = radius; }
- (void)setOuterRadius:(float)radius { self.conf->radius_outer = radius; }

- (void)setRadianOffset:(float)radian { self.conf->radian_offset = radian; }
- (void)setRadianScale:(float)scale { self.conf->radian_scale = scale; }

- (void)setRadiusInner:(float)inner outer:(float)outer
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

- (void)setInnerRadius:(float)radius { self.attr->radius_inner = radius; }
- (void)setOuterRadius:(float)radius { self.attr->radius_outer = radius; }
- (void)setRadiusInner:(float)inner outer:(float)outer
{
	self.attr->radius_inner = inner;
	self.attr->radius_outer = outer;
}

- (void)setColorVec:(vector_float4)color { self.attr->color = color; }

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



