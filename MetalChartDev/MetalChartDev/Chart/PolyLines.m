//
//  PolyLines.m
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/06.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "PolyLines.h"

@interface IndexedPolyLine()

@property (strong, nonatomic) VertexBuffer *vertices;
@property (strong, nonatomic) IndexBuffer *indices;
@property (strong, nonatomic) UniformSeriesInfo *info;

@end

@implementation IndexedPolyLine

- (id)initWithResource:(DeviceResource *)resource
		VertexCapacity:(NSUInteger)vertCapacity
		 indexCapacity:(NSUInteger)idxCapacity
{
	self = [super init];
	if(self) {
		_vertices = [[VertexBuffer alloc] initWithResource:resource capacity:vertCapacity];
		_indices = [[IndexBuffer alloc] initWithResource:resource capacity:idxCapacity];
		_info = [[UniformSeriesInfo alloc] initWithResource:resource];
		_attributes = [[UniformLineAttributes alloc] initWithResource:resource];
		
		[_info info]->vertex_capacity = vertCapacity;
		[_info info]->index_capacity = idxCapacity;
	}
	return self;
}

- (void)setSampleData
{
	const NSUInteger vCount = _vertices.capacity;
	const NSUInteger iCount = _indices.capacity;
	for(int i = 0; i < vCount; ++i) {
		vertex_buffer *v = [_vertices bufferAtIndex:i];
		const float range = 0.5;
		v->position.x = ((2 * ((i  ) % 2)) - 1) * range;
		v->position.y = ((2 * ((i/2) % 2)) - 1) * range;
	}
	for(int i = 0; i < iCount; ++i) {
		index_buffer *idx = [_indices bufferAtIndex:i];
		idx->index = i % vCount;
	}
	_info.offset = 0;
	_info.count = iCount;
	
	[_attributes setColorWithRed:1 green:1 blue:0 alpha:0.5];
	[_attributes setWidth:3];
	[_attributes setModifyAlphaOnEdge:NO];
	_attributes.enableOverlay = NO;
}

@end

