 //
//  VertexBuffer.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/05.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import <Metal/Metal.h>
#include "Engine_common.h"
#import "DeviceResource.h"

#ifndef __Buffers_h__
#define __Buffers_h__

#ifdef __cplusplus
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"

#include <memory>

struct MTLObjectBufferBase {
	
	MTLObjectBufferBase(id<MTLDevice> _Nonnull device,
						NSUInteger capacity,
						NSUInteger elementSize,
						MTLResourceOptions options)
	: _capacity(capacity),
	_elementSize(elementSize),
	_options(options),
	_buffer([device newBufferWithLength:(elementSize*capacity) options:options])
	{
	}
	
	virtual ~MTLObjectBufferBase() {}
	
	id<MTLBuffer> _Nonnull buffer() const { return _buffer; }
	
	NSUInteger capacity() const { return _capacity; }
	NSUInteger elementSize() const { return _elementSize; }
	
	void reserve(NSUInteger newCapacity) {
		if(newCapacity > capacity()) {
			id<MTLBuffer> buf = buffer();
			const NSUInteger length = newCapacity * elementSize();
			_buffer = [[buf device] newBufferWithBytes:[buf contents]
												length:length
											   options:_options];
			_capacity = newCapacity;
		}
	}
	
private :
	
	id<MTLBuffer> _Nonnull _buffer;
	NSUInteger _capacity;
	const NSUInteger _elementSize;
	const MTLResourceOptions _options;
	
};

template <typename T>
struct MTLObjectBuffer : MTLObjectBufferBase {
	
	MTLObjectBuffer(id<MTLDevice> _Nonnull device,
					NSInteger capacity = 1,
					MTLResourceOptions options = MTLResourceOptionCPUCacheModeWriteCombined)
	: MTLObjectBufferBase(device, capacity, sizeof(T), options)
	{
	}
	
	T& operator[](std::size_t index) {
		return (reinterpret_cast<T*>([buffer() contents]))[index];
	}
	
private :
	
	
};

#pragma clang diagnostic pop
#endif


@interface ArrayBuffer : NSObject

@property (readonly, nonatomic) id<MTLBuffer> _Nonnull buffer;
@property (readonly, nonatomic) NSUInteger capacity;

- (void)reserve:(NSUInteger)capacity;

- (instancetype _Nonnull)init
UNAVAILABLE_ATTRIBUTE;

#ifdef __cplusplus

@property (nonatomic, readonly) std::shared_ptr<MTLObjectBufferBase> objectBuffer;

- (instancetype _Nonnull )initWithBuffer:(std::shared_ptr<MTLObjectBufferBase>)buffer
;

#endif

@end






@interface VertexBuffer : ArrayBuffer

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource capacity:(NSUInteger)capacity;

- (vertex_float2 * _Nonnull)bufferAtIndex:(NSUInteger)index;

@end






@interface IndexBuffer : ArrayBuffer

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
								 capacity:(NSUInteger)capacity
NS_DESIGNATED_INITIALIZER;

- (vertex_index * _Nonnull)bufferAtIndex:(NSUInteger)index;

@end





@interface FMIndexedFloatBuffer : ArrayBuffer

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
								 capacity:(NSUInteger)capacity
NS_DESIGNATED_INITIALIZER;

- (indexed_float * _Nonnull)bufferAtIndex:(NSUInteger)index;

- (void)setValue:(float)value index:(uint32_t)index atIndex:(NSUInteger)bufferIndex
;

@end


@interface FMIndexedFloat2Buffer : ArrayBuffer

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
								 capacity:(NSUInteger)capacity
NS_DESIGNATED_INITIALIZER;

- (indexed_float2 * _Nonnull)bufferAtIndex:(NSUInteger)index;

- (void)setValueX:(float)x Y:(float)y index:(uint32_t)index atIndex:(NSUInteger)bufferIndex
;

@end



// このクラスだけScissorRectやらscreenScaleやらを考慮した上でvalueOffsetとかsizeとvalueScaleを
// 設定しなければいけないので煩雑になる。

@interface FMUniformProjectionCartesian2D : NSObject

@property (readonly, nonatomic) id<MTLBuffer> _Nonnull buffer;
@property (readonly, nonatomic) uniform_projection_cart2d * _Nonnull projection;
@property (readonly, nonatomic) CGFloat screenScale;
@property (assign, nonatomic) NSUInteger sampleCount;
@property (assign, nonatomic) MTLPixelFormat colorPixelFormat;
@property (assign, nonatomic) CGSize physicalSize;
@property (assign, nonatomic) RectPadding padding;
@property (assign, nonatomic) CGSize valueScale;
@property (assign, nonatomic) CGPoint valueOffset;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init
UNAVAILABLE_ATTRIBUTE;

- (void)setPixelSize:(CGSize)size;

- (void)setOrigin:(CGPoint)origin;

@end




@interface FMUniformProjectionPolar : NSObject

@property (nonatomic, readonly) id<MTLBuffer> _Nonnull buffer;
@property (nonatomic, readonly) uniform_projection_polar * _Nonnull projection;
@property (nonatomic, readonly) CGFloat screenScale;
@property (nonatomic) NSUInteger sampleCount;
@property (nonatomic) MTLPixelFormat colorPixelFormat;
@property (nonatomic) CGSize physicalSize;
@property (nonatomic) RectPadding padding;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init
UNAVAILABLE_ATTRIBUTE;

- (void)setPixelSize:(CGSize)size;

- (void)setOriginInNDC:(CGPoint)origin;

- (void)setOriginOffset:(CGPoint)offset;

- (void)setAngularOffset:(CGFloat)offsetRad;

- (void)setRadiusScale:(CGFloat)scale;

@end




@interface FMUniformSeriesInfo : NSObject

@property (readonly, nonatomic) id<MTLBuffer> _Nonnull buffer;
@property (assign, nonatomic) NSUInteger count;
@property (assign, nonatomic) NSUInteger offset;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource;

- (uniform_series_info * _Nonnull)info;

- (void)clear;

@end


#endif
