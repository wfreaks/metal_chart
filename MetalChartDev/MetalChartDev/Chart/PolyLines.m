//
//  PolyLines.m
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/06.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "PolyLines.h"

@interface Line()

@property (strong, nonatomic) VertexBuffer *vertices;
@property (strong, nonatomic) UniformSeriesInfo *info;

@end

@interface IndexedPolyLine()

@property (strong, nonatomic) IndexBuffer *indices;

@end


@implementation Line

- (id)initWithResource:(DeviceResource *)resource
        vertexCapacity:(NSUInteger)vertCapacity
{
    self = [super init];
    if(self) {
        _vertices = [[VertexBuffer alloc] initWithResource:resource capacity:vertCapacity];
        _info = [[UniformSeriesInfo alloc] initWithResource:resource];
        _attributes = [[UniformLineAttributes alloc] initWithResource:resource];
        
        [_info info]->vertex_capacity = vertCapacity;
    }
    return self;
}

- (void)encodeTo:(id<MTLCommandBuffer>)command
      renderPass:(MTLRenderPassDescriptor *)pass
      projection:(UniformProjection *)projection
          engine:(LineEngine *)engine
{
    
}

@end

@implementation OrderedPolyLine

- (void)encodeTo:(id<MTLCommandBuffer>)command
      renderPass:(MTLRenderPassDescriptor *)pass
      projection:(UniformProjection *)projection
          engine:(LineEngine *)engine
{
    [engine encodeTo:command
                pass:pass
              vertex:self.vertices
               index:nil
          projection:projection
          attributes:self.attributes
          seriesInfo:self.info];
}

- (void)setSampleData
{
    const NSUInteger vCount = self.vertices.capacity;
    for(int i = 0; i < vCount; ++i) {
        vertex_buffer *v = [self.vertices bufferAtIndex:i];
        const float range = 0.5;
        v->position.x = ((2 * ((i  ) % 2)) - 1) * range;
        v->position.y = ((2 * ((i/2) % 2)) - 1) * range;
    }
    self.info.offset = 0;
    
    [self setSampleAttributes];
}

- (void)setSampleAttributes
{
    UniformLineAttributes *attributes = self.attributes;
    [attributes setColorWithRed:1 green:1 blue:0 alpha:0.5];
    [attributes setWidth:3];
    [attributes setModifyAlphaOnEdge:YES];
    attributes.enableOverlay = YES;
}

- (void)appendSampleData:(NSUInteger)count
{
    const NSUInteger capacity = self.vertices.capacity;
    const NSUInteger idx_start = self.info.offset + self.info.count;
    for(NSUInteger i = 0; i < count; ++i) {
        vertex_buffer *v = [self.vertices bufferAtIndex:(idx_start+i)%capacity];
        v->position.x = idx_start + i;
        v->position.y = ( rand() / (float)RAND_MAX ) - 0.5;
    }
}

@end

@implementation IndexedPolyLine

- (id)initWithResource:(DeviceResource *)resource
		VertexCapacity:(NSUInteger)vertCapacity
		 indexCapacity:(NSUInteger)idxCapacity
{
	self = [super initWithResource:resource vertexCapacity:vertCapacity];
	if(self) {
		_indices = [[IndexBuffer alloc] initWithResource:resource capacity:idxCapacity];
		
		[self.info info]->index_capacity = (uint32_t)idxCapacity;
	}
	return self;
}

- (void)encodeTo:(id<MTLCommandBuffer>)command
      renderPass:(MTLRenderPassDescriptor *)pass
      projection:(UniformProjection *)projection
          engine:(LineEngine *)engine
{
    [engine encodeTo:command
                pass:pass
              vertex:self.vertices
               index:self.indices
          projection:projection
          attributes:self.attributes
          seriesInfo:self.info];
}

@end

