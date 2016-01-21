 //
//  VertexBuffer.h
//  MetalChartDev
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

template <typename T>
struct MTLObjectBuffer {
	
	MTLObjectBuffer(id<MTLDevice> _Nonnull device,
					NSInteger capacity = 1,
					MTLResourceOptions options = MTLResourceOptionCPUCacheModeWriteCombined)
	: _capacity(capacity),
	  _buffer([device newBufferWithLength:(sizeof(T)*capacity) options:options])
	{
	}
	
	T& operator[](std::size_t index) {
		return (reinterpret_cast<T*>([_buffer contents]))[index];
	}
	
	id<MTLBuffer> _Nonnull getBuffer() { return _buffer; }
	
private :
	
	id<MTLBuffer> _Nonnull _buffer;
	const NSInteger _capacity;
	
};

#pragma clang diagnostic pop
#endif

@interface VertexBuffer : NSObject

@property (readonly, nonatomic) id<MTLBuffer> _Nonnull buffer;

@property (readonly, nonatomic) NSUInteger capacity;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource capacity:(NSUInteger)capacity;

- (vertex_buffer * _Nonnull)bufferAtIndex:(NSUInteger)index;


#ifdef __cplusplus

- (std::shared_ptr<vertex_container>)container;

#endif

@end






@interface IndexBuffer : NSObject

@property (readonly, nonatomic) id<MTLBuffer> _Nonnull buffer;
@property (readonly, nonatomic) NSUInteger capacity;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource capacity:(NSUInteger)capacity;

- (index_buffer * _Nonnull)bufferAtIndex:(NSUInteger)index;

#ifdef __cplusplus

- (std::shared_ptr<index_container>)container;

#endif

@end





@interface FMIndexedFloatBuffer : NSObject

@property (nonatomic, readonly) id<MTLBuffer> _Nonnull buffer;
@property (nonatomic, readonly) NSUInteger capacity;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
								 capacity:(NSUInteger)capacity
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init
UNAVAILABLE_ATTRIBUTE;

- (indexed_value_float * _Nonnull)bufferAtIndex:(NSUInteger)index;

- (void)setValue:(float)value index:(uint32_t)index atIndex:(NSUInteger)bufferIndex
;

@end


@interface FMIndexedFloat2Buffer : NSObject

@property (nonatomic, readonly) id<MTLBuffer> _Nonnull buffer;
@property (nonatomic, readonly) NSUInteger capacity;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
								 capacity:(NSUInteger)capacity
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init
UNAVAILABLE_ATTRIBUTE;

- (indexed_value_float2 * _Nonnull)bufferAtIndex:(NSUInteger)index;

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

@end


#endif
