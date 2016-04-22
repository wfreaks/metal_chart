//
//  Series.m
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/11.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "Series.h"

@interface FMOrderedSeries()

@end

@implementation FMOrderedSeries

- (instancetype)initWithResource:(FMDeviceResource *)resource
				  vertexCapacity:(NSUInteger)vertCapacity
{
	self = [super init];
	if(self) {
		_vertices = [[FMFloat2Buffer alloc] initWithResource:resource capacity:vertCapacity];
		_info = [[FMUniformSeriesInfo alloc] initWithResource:resource];
		
		[_info info]->vertex_capacity = (uint32_t)vertCapacity;
	}
	return self;
}

- (id<MTLBuffer>)vertexBuffer { return _vertices.buffer; }

- (void)addPoint:(CGPoint)point
{
	[self addPoint:point maxCount:_vertices.capacity];
}

- (void)addPoint:(CGPoint)point maxCount:(NSUInteger)max
{
	@synchronized(self) {
		const NSUInteger count = _info.count;
		const NSUInteger offset = _info.offset;
		const NSUInteger idx = count + offset;
		[_vertices bufferAtIndex:idx]->position = vector2((float)point.x, (float)point.y);
		if(0 < max && max <= count) {
			_info.offset = (offset + 1);
		} else {
			_info.count = (count + 1);
		}
	}
}

- (void)reserve:(NSUInteger)capacity
{
	if(capacity > self.vertices.capacity) {
		[self.vertices reserve:capacity];
		_info.offset = 0;
		[_info info]->vertex_capacity = (uint32_t)capacity;
	}
}

@end

@implementation FMOrderedAttributedSeries

- (instancetype)initWithResource:(FMDeviceResource *)resource
				  vertexCapacity:(NSUInteger)vertCapacity
{
	self = [super init];
	if(self) {
		_vertices = [[FMIndexedFloat2Buffer alloc] initWithResource:resource capacity:vertCapacity];
		_info = [[FMUniformSeriesInfo alloc] initWithResource:resource];
		
		[_info info]->vertex_capacity = (uint32_t)vertCapacity;
	}
	return self;
}

- (id<MTLBuffer>)vertexBuffer { return _vertices.buffer; }

- (void)addPoint:(CGPoint)point
{
	[self addPoint:point maxCount:_vertices.capacity attrIndex:0];
}

- (void)addPoint:(CGPoint)point maxCount:(NSUInteger)max
{
	[self addPoint:point maxCount:max attrIndex:0];
}

- (void)addPoint:(CGPoint)point attrIndex:(NSUInteger)attrIndex
{
	[self addPoint:point maxCount:_vertices.capacity attrIndex:attrIndex];
}

- (void)addPoint:(CGPoint)point maxCount:(NSUInteger)max attrIndex:(NSUInteger)attrIndex
{
	@synchronized(self) {
		const NSUInteger count = _info.count;
		const NSUInteger offset = _info.offset;
		const NSUInteger idx = count + offset;
		indexed_float2 *ptr = [_vertices bufferAtIndex:idx];
		ptr->value = vector2((float)point.x, (float)point.y);
		ptr->idx = (uint32_t)attrIndex;
		if(0 < max && max <= count) {
			_info.offset = (offset + 1);
		} else {
			_info.count = (count + 1);
		}
	}
}

- (void)reserve:(NSUInteger)capacity
{
	if(capacity > self.vertices.capacity) {
		[self.vertices reserve:capacity];
		_info.offset = 0;
		[_info info]->vertex_capacity = (uint32_t)capacity;
	}
}

@end


