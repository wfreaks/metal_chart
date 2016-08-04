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


@implementation FMArrayBuffer

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



@implementation FMFloat2Buffer

- (id)initWithResource:(FMDeviceResource *)resource capacity:(NSUInteger)capacity
{
	auto ptr = std::make_shared<MTLObjectBuffer<vertex_float2>>(resource.device, capacity);
	self = [super initWithBuffer:std::static_pointer_cast<MTLObjectBufferBase>(ptr)];
	return self;
}

- (vertex_float2 *)bufferAtIndex:(NSUInteger)index
{
	vertex_float2 *ptr = (vertex_float2 *)([self.buffer contents]);
	return ptr + (index % self.capacity);
}

@end


@implementation FMIndexedFloatBuffer

- (instancetype)initWithResource:(FMDeviceResource *)resource capacity:(NSUInteger)capacity
{
	auto ptr = std::make_shared<MTLObjectBuffer<indexed_float>>(resource.device, capacity);
	self = [super initWithBuffer:std::static_pointer_cast<MTLObjectBufferBase>(ptr)];
	return self;
}

- (indexed_float *)bufferAtIndex:(NSUInteger)index
{
	indexed_float *ptr = (indexed_float *)[self.buffer contents];
	return (ptr + index);
}

- (void)setValue:(float)value index:(uint32_t)index atIndex:(NSUInteger)bufferIndex
{
	indexed_float *buffer = [self bufferAtIndex:bufferIndex];
	buffer->value = value;
	buffer->idx = index;
}

@end


@implementation FMIndexedFloat2Buffer

- (instancetype)initWithResource:(FMDeviceResource *)resource capacity:(NSUInteger)capacity
{
	auto ptr = std::make_shared<MTLObjectBuffer<indexed_float2>>(resource.device, capacity);
	self = [super initWithBuffer:std::static_pointer_cast<MTLObjectBufferBase>(ptr)];
	return self;
}

- (indexed_float2 *)bufferAtIndex:(NSUInteger)index
{
	indexed_float2 *ptr = (indexed_float2 *)[self.buffer contents];
	return (ptr + index);
}

- (void)setValueX:(float)x Y:(float)y index:(uint32_t)index atIndex:(NSUInteger)bufferIndex
{
	indexed_float2 *buffer = [self bufferAtIndex:bufferIndex];
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

- (void)setPadding:(FMRectPadding)padding
{
	if(!FMRectPaddingEqualsTo(_padding, padding)) {
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

- (void)setPadding:(FMRectPadding)padding
{
	if(!FMRectPaddingEqualsTo(_padding, padding)) {
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



@implementation FMAttributesBuffer

- (instancetype)initWithBuffer:(id<MTLBuffer>)buffer index:(NSInteger)index
{
    self = [super init];
    if(self) {
        _buffer = buffer;
        _index = index;
    }
    return self;
}

- (instancetype)initWithResource:(FMDeviceResource *)resource size:(NSUInteger)size
{
	self = [super init];
	if(self) {
		_buffer = [resource.device newBufferWithLength:size options:MTLResourceOptionCPUCacheModeWriteCombined];
		_index = 0;
	}
	return self;
}

@end


@implementation FMAttributesArray

- (instancetype)initWithBuffer:(std::shared_ptr<MTLObjectBufferBase>)buffer
{
	self = [super initWithBuffer:buffer];
	if(self) {
		_array = [self.class createArrayWithBuffer:self.buffer capacity:buffer->capacity()];
	}
	return self;
}

+ (NSArray<FMAttributesBuffer*>*)createArrayWithBuffer:(id<MTLBuffer>)buffer capacity:(NSUInteger)capacity
{
	Class cl = [self attributesClass];
	NSMutableArray<FMAttributesBuffer*>* array = [NSMutableArray arrayWithCapacity:capacity];
	for(NSInteger i = 0; i < capacity; ++i) {
		[array addObject:[[cl alloc] initWithBuffer:buffer index:i]];
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

- (id)objectAtIndexedSubscript:(NSUInteger)index
{
	return _array[index];
}



+ (Class)attributesClass { abort(); }

@end

