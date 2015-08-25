//
//  VertexBuffer.m
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/08/05.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <UIKit/UIColor.h>
#import <UIKit/UIScreen.h>
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

@interface UniformAxisAttributes()

- (instancetype)initWithAttributes:(uniform_axis_attributes *)attr;

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

- (NSUInteger)capacity
{
    return _container->capacity();
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

- (NSUInteger)capacity
{
    return _container->capacity();
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
		_screenScale = [UIScreen mainScreen].scale;
        [self projection]->screen_scale = _screenScale;
    }
    return self;
}

- (uniform_projection *)projection
{
    return (uniform_projection *)([self.buffer contents]);
}

- (void)setPhysicalSize:(CGSize)size
{
	_physicalSize = size;
    uniform_projection *ptr = [self projection];
    ptr->physical_size = vector2((float)size.width, (float)size.height);
}

- (void)setPixelSize:(CGSize)size
{
    const CGFloat scale = [UIScreen mainScreen].scale;
    uniform_projection *ptr = [self projection];
	const CGFloat w = (size.width/scale);
	const CGFloat h = (size.height/scale);
	_physicalSize.width = w;
	_physicalSize.height = h;
    ptr->physical_size = vector2((float)w, (float)h);
}

- (void)setValueScale:(CGSize)scale
{
    uniform_projection *ptr = [self projection];
    ptr->value_scale = vector2((float)scale.width, (float)scale.height);
}

- (void)setOrigin:(CGPoint)origin
{
    uniform_projection *ptr = [self projection];
    ptr->origin = vector2((float)origin.x, (float)origin.y);
}

- (void)setValueOffset:(CGSize)offset
{
    uniform_projection *ptr = [self projection];
    ptr->value_offset = vector2((float)offset.width, (float)offset.height);
}

- (void)setPadding:(RectPadding)padding
{
	_padding = padding;
	uniform_projection *ptr = [self projection];
	ptr->rect_padding = vector4((float)padding.left, (float)padding.top, (float)padding.right, (float)padding.bottom);
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

- (void)setWidth:(CGFloat)width
{
    [self attributes]->width = (float)width;
}

- (void)setColorWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha
{
    [self attributes]->color = vector4(red, green, blue, alpha);
}

- (void)setModifyAlphaOnEdge:(BOOL)modify
{
    [self attributes]->modify_alpha_on_edge = (modify ? 1 : 0);
}

- (void)setEnableOverlay:(BOOL)enableOverlay
{
	_enableOverlay = enableOverlay;
	[self setModifyAlphaOnEdge:enableOverlay];
}

- (void)setLineLengthModifierStart:(float)start end:(float)end
{
	[self attributes]->length_mod = vector2(start, end);
}

- (void)setDepthValue:(float)depth
{
    [self attributes]->depth = depth;
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

- (void)setOffset:(NSUInteger)offset
{
	_offset = offset;
	[self info]->offset = (uint32_t)offset;
}

@end


@implementation UniformAxisAttributes

- (instancetype)initWithAttributes:(uniform_axis_attributes *)attr
{
    self = [super init];
    if(self) {
        _attributes = attr;
		_attributes->length_mod = vector2((float)-1, (float)1);
    }
    return self;
}

- (void)setWidth:(float)width { _attributes->width = width; }

- (void)setLineLength:(float)length { _attributes->line_length = length; }

- (void)setColorWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha
{
    _attributes->color = vector4(red, green, blue, alpha);
}

- (void)setLengthModifierStart:(float)start end:(float)end
{
    _attributes->length_mod = vector2(start, end);
}

@end

@implementation UniformAxis

- (instancetype)initWithResource:(DeviceResource *)resource
{
    self = [super init];
    if(self) {
        id<MTLDevice> device = resource.device;
        _axisBuffer = [device newBufferWithLength:sizeof(uniform_axis) options:MTLResourceOptionCPUCacheModeWriteCombined];
        _attributeBuffer = [device newBufferWithLength:(sizeof(uniform_axis_attributes[3])) options:MTLResourceOptionCPUCacheModeWriteCombined];
        _axisAttributes = [[UniformAxisAttributes alloc] initWithAttributes:[self attributesAtIndex:0]];
        _majorTickAttributes = [[UniformAxisAttributes alloc] initWithAttributes:[self attributesAtIndex:1]];
        _minorTickAttributes = [[UniformAxisAttributes alloc] initWithAttributes:[self attributesAtIndex:2]];
    }
    return self;
}

- (uniform_axis *)axis {
    return (uniform_axis *)[_axisBuffer contents];
}

- (uniform_axis_attributes *)attributesAtIndex:(NSUInteger)index
{
    return ((uniform_axis_attributes *)[_attributeBuffer contents]) + index;
}

- (void)setAxisAnchorValue:(float)value
{
	if(_axisAnchorValue != value) {
		_axisAnchorValue = value;
		[self axis]->axis_anchor_value = value;
	}
}

- (void)setTickAnchorValue:(float)value
{
	if( _tickAnchorValue != value ) {
		_tickAnchorValue = value;
		[self axis]->tick_anchor_value = value;
	}
}

- (void)setMajorTickInterval:(float)interval
{
	if( _majorTickInterval != interval ) {
		_majorTickInterval = interval;
		[self axis]->tick_interval_major = interval;
	}
}

- (void)setDimensionIndex:(uint8_t)index
{
	[self axis]->dimIndex = index;
}

- (void)setMinorTicksPerMajor:(uint8_t)count {
    _minorTicksPerMajor = count;
    [self axis]->minor_ticks_per_major = count;
}

- (void)setMaxMajorTicks:(uint8_t)count {
    _maxMajorTicks = count;
    [self axis]->max_major_ticks = count;
}

@end




