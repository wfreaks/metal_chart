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
#import "Prototypes.h"

#ifndef __Buffers_h__
#define __Buffers_h__

#ifdef __cplusplus
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"

#include <memory>

/**
 * A base struct to provide common functionalities and interface to MTLObjectBuffer<T> regardless of type parameters.
 */

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

/**
 * A templated struct that provides a member method that casts a pointer referencing underlying buffer region to a reference of typed element.
 */
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


/**
 * A buffer object that owns a gpu buffer, and can extend region by calling reserve: on it.
 * Obviously it is a mere obj-c wrapper of MTLObjectBufferBase.
 * (Subclasses allocate MTLObjectBuffer<T> depending on an element type they need, and pass them to super(this class)).
 */
@interface FMArrayBuffer : NSObject

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




/**
 * A wrapper class for MTLObjectBuffer<vertex_float2>.
 */

@interface FMFloat2Buffer : FMArrayBuffer

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource capacity:(NSUInteger)capacity;

- (vertex_float2 * _Nonnull)bufferAtIndex:(NSUInteger)index;

@end




/**
 * A wrapper cass for MTLObjectBuffer<indexed_float>.
 */

@interface FMIndexedFloatBuffer : FMArrayBuffer

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
								 capacity:(NSUInteger)capacity
NS_DESIGNATED_INITIALIZER;

- (indexed_float * _Nonnull)bufferAtIndex:(NSUInteger)index;

- (void)setValue:(float)value index:(uint32_t)index atIndex:(NSUInteger)bufferIndex
;

@end



/**
 * A wrapper cass for MTLObjectBuffer<indexed_float2>.
 */

@interface FMIndexedFloat2Buffer : FMArrayBuffer

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
								 capacity:(NSUInteger)capacity
NS_DESIGNATED_INITIALIZER;

- (indexed_float2 * _Nonnull)bufferAtIndex:(NSUInteger)index;

- (void)setValueX:(float)x Y:(float)y index:(uint32_t)index atIndex:(NSUInteger)bufferIndex
;

@end


/**
 * A wrapper class that hosts gpu buffer for FMProejctionCartesian2D and that provides methods to modify its members.
 * You won't have to use this class unless you are writing custom shaders for visualizing data in 2-dimensional cartesian space.
 */

@interface FMUniformProjectionCartesian2D : NSObject

@property (readonly, nonatomic) id<MTLBuffer> _Nonnull buffer;
@property (readonly, nonatomic) uniform_projection_cart2d * _Nonnull projection;
@property (readonly, nonatomic) CGFloat screenScale;
@property (assign, nonatomic) CGSize physicalSize;
@property (assign, nonatomic) RectPadding padding;
@property (assign, nonatomic) CGSize valueScale;
@property (assign, nonatomic) CGPoint valueOffset;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init
UNAVAILABLE_ATTRIBUTE;

/**
 * sets physicalSize (size in logical pixels) property using physical pixels (device pixels) using screenScale property.
 */
- (void)setPixelSize:(CGSize)size;

- (void)setOrigin:(CGPoint)origin;

@end



/**
 * A wrapper class that hosts gpu buffer for FMProjectionPolar and that provides methods to modify its members.
 * You won't have to use this class unless you are writing custom shaders for visualizing data in 2-dimensional polar space.
 */

@interface FMUniformProjectionPolar : NSObject

@property (nonatomic, readonly) id<MTLBuffer> _Nonnull buffer;
@property (nonatomic, readonly) uniform_projection_polar * _Nonnull projection;
@property (nonatomic, readonly) CGFloat screenScale;
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



/**
 * A wrapper class that hosts gpu buffer for FMSeriesInfo and that provides methods to modify its members.
 */

@interface FMUniformSeriesInfo : NSObject

@property (readonly, nonatomic) id<MTLBuffer> _Nonnull buffer;
@property (assign, nonatomic) NSUInteger count;
@property (assign, nonatomic) NSUInteger offset;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource;

- (uniform_series_info * _Nonnull)info;

/**
 * clears count and offset properties to zero.
 */
- (void)clear;

@end




/**
 * A helper class for FMAttributesArray<Type>.
 * A class that can be an element type of FMAttributesArray class should be derived from this.
 *
 * Subclass must takes care of index property when provides a getter method/property for an underlying element
 * since the parameter buffer of initWithBuffer:index can be an array buffer.
 */

@interface FMAttributesBuffer : NSObject

@property (readonly, nonatomic) id<MTLBuffer> _Nonnull buffer;
@property (readonly, nonatomic) NSInteger index;

- (instancetype _Nonnull)init
UNAVAILABLE_ATTRIBUTE;

- (instancetype _Nonnull)initWithBuffer:(id<MTLBuffer> _Nonnull)buffer
                                  index:(NSInteger)index
;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
                                     size:(NSUInteger)size
;

@end


/**
 * A base class that helps implementing a class that holds an array of an attributes class (gpu-backed objc class that provides getter/setter methods).
 *
 * Subclasses must override attributesClass and provide initWithResource:capacity or such.
 * (it's more precise to specify UNAVAILABLE_ATTRIBUTES for initWithResource:size: but you may ignore this)
 * subclasses can be used with indexed subscription (i.e. [array[idx] setAttributeA:someValue].
 */

@interface FMAttributesArray<AttributesType> : FMArrayBuffer

@property (nonatomic, readonly) NSArray<AttributesType>* _Nonnull array;

/**
 * subclasses must return a class that is derived from FMAttributesBuffer and from type parameter AttributesType.
 * instances of the class returned will be created and initialized with initWithBuffer:index.
 */
+ (Class _Nonnull)attributesClass;

- (AttributesType _Nonnull)objectAtIndexedSubscript:(NSUInteger)index;

@end


#endif
