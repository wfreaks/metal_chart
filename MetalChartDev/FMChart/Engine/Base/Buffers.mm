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



@interface FMUniformProjectionCartesian2D()

@property (strong, nonatomic) id<MTLBuffer> buffer;

@end




@interface FMUniformSeriesInfo()

@property (strong, nonatomic) id<MTLBuffer> buffer;

@end

#pragma mark - Implementation


@implementation VertexBuffer

- (id)initWithResource:(FMDeviceResource *)resource capacity:(NSUInteger)capacity
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
    return ptr + (index % self.capacity);
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

- (id)initWithResource:(FMDeviceResource *)resource capacity:(NSUInteger)capacity
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



@implementation FMIndexedFloatBuffer

- (instancetype)initWithResource:(FMDeviceResource *)resource capacity:(NSUInteger)capacity
{
	self = [super init];
	if(self) {
		const NSUInteger length = sizeof(indexed_value_float) * capacity;
		_buffer = [resource.device newBufferWithLength:length options:MTLResourceOptionCPUCacheModeWriteCombined];
		_capacity = capacity;
	}
	return self;
}

- (indexed_value_float *)bufferAtIndex:(NSUInteger)index
{
	indexed_value_float *ptr = (indexed_value_float *)[_buffer contents];
	return (ptr + index);
}

- (void)setValue:(float)value index:(uint32_t)index atIndex:(NSUInteger)bufferIndex
{
	indexed_value_float *buffer = ((indexed_value_float *)[_buffer contents]) + bufferIndex;
	buffer->value = value;
	buffer->idx = index;
}

@end


@implementation FMIndexedFloat2Buffer

- (instancetype)initWithResource:(FMDeviceResource *)resource capacity:(NSUInteger)capacity
{
	self = [super init];
	if(self) {
		const NSUInteger length = sizeof(indexed_value_float2) * capacity;
		_buffer = [resource.device newBufferWithLength:length options:MTLResourceOptionCPUCacheModeWriteCombined];
		_capacity = capacity;
	}
	return self;
}

- (indexed_value_float2 *)bufferAtIndex:(NSUInteger)index
{
	indexed_value_float2 *ptr = (indexed_value_float2 *)[_buffer contents];
	return (ptr + index);
}

- (void)setValueX:(float)x Y:(float)y index:(uint32_t)index atIndex:(NSUInteger)bufferIndex
{
	indexed_value_float2 *buffer = ((indexed_value_float2 *)[_buffer contents]) + bufferIndex;
	buffer->value = vector2(x, y);
	buffer->idx = index;
}

@end



@implementation FMUniformProjectionCartesian2D

- (id)initWithResource:(FMDeviceResource *)resource
{
    self = [super init];
    if(self) {
        _buffer = [resource.device newBufferWithLength:sizeof(uniform_projection_cart2d) options:MTLResourceOptionCPUCacheModeWriteCombined];
		_screenScale = [UIScreen mainScreen].scale;
        [self projection]->screen_scale = _screenScale;
        [self projection]->value_scale = vector2(1.0f, 1.0f);
    }
    return self;
}

- (uniform_projection_cart2d *)projection
{
    return (uniform_projection_cart2d *)([self.buffer contents]);
}

- (void)setPhysicalSize:(CGSize)size
{
	if(!CGSizeEqualToSize(size, _physicalSize)) {
		_physicalSize = size;
		self.projection->physical_size = vector2((float)size.width, (float)size.height);
	}
}

- (void)setPixelSize:(CGSize)size
{
    const CGFloat scale = _screenScale;
	const CGFloat w = (size.width/scale);
	const CGFloat h = (size.height/scale);
	self.physicalSize = CGSizeMake(w, h);
}

- (void)setPadding:(RectPadding)padding
{
	if(!RectPaddingEqualsTo(_padding, padding)) {
		_padding = padding;
		self.projection->rect_padding = vector4((float)padding.left, (float)padding.top, (float)padding.right, (float)padding.bottom);
	}
}

- (void)setValueScale:(CGSize)scale
{
    self.projection->value_scale = vector2((float)scale.width, (float)scale.height);
}

- (void)setOrigin:(CGPoint)origin
{
    self.projection->origin = vector2((float)origin.x, (float)origin.y);
}

- (void)setValueOffset:(CGSize)offset
{
    self.projection->value_offset = vector2((float)offset.width, (float)offset.height);
}

@end



@implementation FMUniformProjectionPolar

- (instancetype _Nonnull)initWithResource:(FMDeviceResource *)resource
{
	self = [super init];
	if(self) {
		const NSInteger size = sizeof(uniform_projection_polar);
		_buffer = [resource.device newBufferWithLength:size options:MTLResourceOptionCPUCacheModeWriteCombined];
		_screenScale = [UIScreen mainScreen].scale;
		self.projection->screen_scale = _screenScale;
		[self setRadiusScale:1];
	}
	return self;
}

- (uniform_projection_polar *)projection {
	return (uniform_projection_polar *)[_buffer contents];
}

- (void)setPhysicalSize:(CGSize)size
{
	if(!CGSizeEqualToSize(size, _physicalSize)) {
		_physicalSize = size;
		self.projection->physical_size = vector2((float)size.width, (float)size.height);
	}
}

- (void)setPixelSize:(CGSize)size
{
	const CGFloat scale = _screenScale;
	const CGFloat w = (size.width/scale);
	const CGFloat h = (size.height/scale);
	self.physicalSize = CGSizeMake(w, h);
}

- (void)setPadding:(RectPadding)padding
{
	if(!RectPaddingEqualsTo(_padding, padding)) {
		_padding = padding;
		self.projection->rect_padding = vector4((float)padding.left, (float)padding.top, (float)padding.right, (float)padding.bottom);
	}
}

- (void)setOriginInNDC:(CGPoint)origin
{
	self.projection->origin_ndc = vector2((float)origin.x, (float)origin.y);
}

- (void)setOriginOffset:(CGPoint)offset
{
	self.projection->origin_offset = vector2((float)offset.x, (float)offset.y);
}

- (void)setAngularOffset:(CGFloat)offsetRad
{
	self.projection->radian_offset = offsetRad;
}

- (void)setRadiusScale:(CGFloat)scale
{
	self.projection->radius_scale = scale;
}

@end



@implementation FMUniformSeriesInfo

- (id)initWithResource:(FMDeviceResource *)resource
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



