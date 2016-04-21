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

@interface FMUniformPointAttributes()

- (instancetype)initWithBuffer:(id<MTLBuffer>)buffer;

@end

@implementation FMUniformPointAttributes

@dynamic point;

- (instancetype)initWithResource:(FMDeviceResource *)resource
{
	self = [super init];
	if(self) {
		_buffer = [resource.device newBufferWithLength:sizeof(uniform_point) options:MTLResourceOptionCPUCacheModeWriteCombined];
		[self setInnerRadius:5];
		[self setOuterRadius:6];
		[self setInnerColorRed:0.1 green:0.5 blue:0.8 alpha:0.6];
		[self setOuterColorRed:0.1 green:0.3 blue:0.5 alpha:1.0];
	}
	return self;
}

- (instancetype)initWithBuffer:(id<MTLBuffer>)buffer
{
	self = [super init];
	if(self) {
		_buffer = buffer;
	}
	return self;
}

- (uniform_point *)point { return (uniform_point *)([_buffer contents]); }

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


@interface FMUniformPointIndexedAttributes : FMUniformPointAttributes
@property (nonatomic, readonly) NSInteger index;
@end

@implementation FMUniformPointIndexedAttributes

- (instancetype)initWithBuffer:(id<MTLBuffer>)buffer index:(NSInteger)index
{
	self = [super initWithBuffer:buffer];
	if(self) {
		_index = index;
	}
	return self;
}

- (uniform_point*)point { return [super point] + _index; }

@end

@implementation FMUniformPointAttributesArray

- (instancetype)initWithResource:(FMDeviceResource *)resource capacity:(NSUInteger)capacity
{
	auto ptr = std::make_shared<MTLObjectBuffer<uniform_point>>(resource.device, capacity);
	self = [super initWithBuffer:std::static_pointer_cast<MTLObjectBufferBase>(ptr)];
	if(self) {
		_array = [self.class createArrayWithBuffer:self.buffer capacity:capacity];
	}
	return self;
}

+ (NSArray<FMUniformPointIndexedAttributes*>*)createArrayWithBuffer:(id<MTLBuffer>)buffer capacity:(NSUInteger)capacity
{
	NSMutableArray<FMUniformPointIndexedAttributes*>* array = [NSMutableArray arrayWithCapacity:capacity];
	for(NSInteger i = 0; i < capacity; ++i) {
		[array addObject:[[FMUniformPointIndexedAttributes alloc] initWithBuffer:buffer index:i]];
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

