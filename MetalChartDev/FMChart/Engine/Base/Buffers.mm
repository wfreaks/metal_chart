//
//  VertexBuffer.m
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/05.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <UIKit/UIColor.h>
#import <UIKit/UIScreen.h>
#import "Buffers.h"

#pragma mark - Private Interfaces



@interface FMUniformProjectionCartesian2D()

@property (strong, nonatomic) id<MTLBuffer> buffer;

@end




@interface FMUniformSeriesInfo()

@property (strong, nonatomic) id<MTLBuffer> buffer;

@end

#pragma mark - Implementation


@implementation ArrayBuffer

- (instancetype)initWithBuffer:(std::shared_ptr<MTLObjectBufferBase>)buffer
{
    self = [super init];
    if(self) {
        _objectBuffer = buffer;
    }
    return self;
}

- (id<MTLBuffer>)buffer { return _objectBuffer->buffer(); }
- (NSUInteger)capacity { return _objectBuffer->capacity(); }

- (void)reserve:(NSUInteger)capacity
{
    _objectBuffer->reserve(capacity);
}

@end



@implementation VertexBuffer

- (id)initWithResource:(FMDeviceResource *)resource capacity:(NSUInteger)capacity
{
    auto ptr = std::make_shared<MTLObjectBuffer<vertex_buffer>>(resource.device, capacity);
    self = [super initWithBuffer:std::static_pointer_cast<MTLObjectBufferBase>(ptr)];
    return self;
}

- (vertex_buffer *)bufferAtIndex:(NSUInteger)index
{
    vertex_buffer *ptr = (vertex_buffer *)([self.buffer contents]);
    return ptr + (index % self.capacity);
}

@end


@implementation IndexBuffer

- (id)initWithResource:(FMDeviceResource *)resource capacity:(NSUInteger)capacity
{
    auto ptr = std::make_shared<MTLObjectBuffer<index_buffer>>(resource.device, capacity);
    self = [super initWithBuffer:std::static_pointer_cast<MTLObjectBufferBase>(ptr)];
    return self;
}

- (index_buffer *)bufferAtIndex:(NSUInteger)index
{
    index_buffer *ptr = (index_buffer *)([self.buffer contents]);
    return ptr + index;
}

@end



@implementation FMIndexedFloatBuffer

- (instancetype)initWithResource:(FMDeviceResource *)resource capacity:(NSUInteger)capacity
{
    auto ptr = std::make_shared<MTLObjectBuffer<indexed_value_float>>(resource.device, capacity);
    self = [super initWithBuffer:std::static_pointer_cast<MTLObjectBufferBase>(ptr)];
    return self;
}

- (indexed_value_float *)bufferAtIndex:(NSUInteger)index
{
	indexed_value_float *ptr = (indexed_value_float *)[self.buffer contents];
	return (ptr + index);
}

- (void)setValue:(float)value index:(uint32_t)index atIndex:(NSUInteger)bufferIndex
{
	indexed_value_float *buffer = [self bufferAtIndex:bufferIndex];
	buffer->value = value;
	buffer->idx = index;
}

@end


@implementation FMIndexedFloat2Buffer

- (instancetype)initWithResource:(FMDeviceResource *)resource capacity:(NSUInteger)capacity
{
    auto ptr = std::make_shared<MTLObjectBuffer<indexed_value_float2>>(resource.device, capacity);
    self = [super initWithBuffer:std::static_pointer_cast<MTLObjectBufferBase>(ptr)];
    return self;
}

- (indexed_value_float2 *)bufferAtIndex:(NSUInteger)index
{
	indexed_value_float2 *ptr = (indexed_value_float2 *)[self.buffer contents];
	return (ptr + index);
}

- (void)setValueX:(float)x Y:(float)y index:(uint32_t)index atIndex:(NSUInteger)bufferIndex
{
	indexed_value_float2 *buffer = [self bufferAtIndex:bufferIndex];
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
        self.valueScale = CGSizeMake(1, 1);
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
    if(!CGSizeEqualToSize(_valueScale, scale)) {
        _valueScale = scale;
        self.projection->value_scale = vector2((float)scale.width, (float)scale.height);
    }
}

- (void)setOrigin:(CGPoint)origin
{
    self.projection->origin = vector2((float)origin.x, (float)origin.y);
}

- (void)setValueOffset:(CGPoint)offset
{
    if(!CGPointEqualToPoint(_valueOffset, offset)) {
        _valueOffset = offset;
        self.projection->value_offset = vector2((float)offset.x, (float)offset.y);
    }
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

- (void)clear
{
	self.offset = 0;
	self.count = 0;
}

@end



