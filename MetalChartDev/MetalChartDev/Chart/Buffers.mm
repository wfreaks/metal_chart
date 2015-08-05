//
//  VertexBuffer.m
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/08/05.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "Buffers.h"

#pragma mark - Private Interfaces

@interface VertexBuffer()

@property (strong, nonatomic) id<MTLBuffer> buffer;
@property (assign, nonatomic) std::shared_ptr<vertex_container> container;

@end



@interface IndexBuffer()

@property (strong, nonatomic) id<MTLBuffer> buffer;
@property (assign, nonatomic) std::shared_ptr<index_container> container;

@end



@interface UniformProjection()

@property (strong, nonatomic) id<MTLBuffer> buffer;

@end



@interface UniformLineAttributes()

@property (strong, nonatomic) id<MTLBuffer> buffer;

@end



@interface UniformSeriesInfo()

@property (strong, nonatomic) id<MTLBuffer> buffer;

@end


#pragma mark - Implementation


@implementation VertexBuffer

- (id)initWithResource:(DeviceResource *)resource capacity:(NSUInteger)capacity
{
    self = [super init];
    if(self) {
        const NSUInteger length = sizeof(vertex_buffer) * capacity;
        _buffer = [resource.device newBufferWithLength:length options:MTLResourceOptionCPUCacheModeWriteCombined];
        _container = std::make_shared<vertex_container>([_buffer contents], capacity);
    }
    return self;
}

- (vertex_buffer *)bufferAtIndex:(NSUInteger)index
{
    vertex_buffer *ptr = (vertex_buffer *)([self.buffer contents]);
    return ptr + index;
}

- (void)dealloc
{
    _container = nullptr;
}

@end


@implementation IndexBuffer

- (id)initWithResource:(DeviceResource *)resource capacity:(NSUInteger)capacity
{
    self = [super init];
    if(self) {
        const NSUInteger length = sizeof(index_buffer) * capacity;
        _buffer = [resource.device newBufferWithLength:length options:MTLResourceOptionCPUCacheModeWriteCombined];
        _container = std::make_shared<index_container>([_buffer contents], capacity);
    }
    return self;
}

- (index_buffer *)bufferAtIndex:(NSUInteger)index
{
    index_buffer *ptr = (index_buffer *)([self.buffer contents]);
    return ptr + index;
}

- (void)dealloc
{
    _container = nullptr;
}

@end



@implementation UniformProjection

- (id)initWithResource:(DeviceResource *)resource
{
    self = [super init];
    if(self) {
        _buffer = [resource.device newBufferWithLength:sizeof(uniform_projection) options:MTLResourceOptionCPUCacheModeWriteCombined];
    }
    return self;
}

- (uniform_projection *)projection
{
    return (uniform_projection *)([self.buffer contents]);
}

- (void)setPhysicalSize:(CGSize)size
{
    uniform_projection *ptr = [self projection];
    ptr->physical_size = vector2((float)size.width, (float)size.height);
}

@end


@implementation UniformLineAttributes

- (id)initWithResource:(DeviceResource *)resource
{
    self = [super init];
    if(self) {
        _buffer = [resource.device newBufferWithLength:sizeof(uniform_line_attr) options:MTLResourceOptionCPUCacheModeWriteCombined];
    }
    return self;
}

- (uniform_line_attr *)attributes
{
    return (uniform_line_attr *)([self.buffer contents]);
}

@end



@implementation UniformSeriesInfo

- (id)initWithResource:(DeviceResource *)resource
{
    self = [super init];
    if(self) {
        _buffer = [resource.device newBufferWithLength:sizeof(uniform_series_info) options:MTLResourceOptionCPUCacheModeWriteCombined];
    }
    return self;
}

- (uniform_series_info *)info
{
    return (uniform_series_info *)([self.buffer contents]);
}

@end



