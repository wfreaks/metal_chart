//
//  LineEngine_common.h
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/08/03.
//  Copyright © 2015年 freaks. All rights reserved.
//

#ifndef LineEngine_common_h
#define LineEngine_common_h

#include <simd/simd.h>
#include <CoreGraphics/CGGeometry.h>

typedef struct RectPadding {
	CGFloat left;
	CGFloat top;
	CGFloat right;
	CGFloat bottom;
} RectPadding;

typedef struct uniform_projection {
    vector_float2 physical_size;
    float screen_scale;
	vector_float4 rect_padding;
    
    vector_float2 origin;
    vector_float2 value_scale;
    vector_float2 value_offset;
} uniform_projection;

typedef struct uniform_line_attr {
    float width;
    vector_float4 color;
    uint8_t modify_alpha_on_edge;
} uniform_line_attr;

typedef struct uniform_series_info {
    uint32_t vertex_capacity;
    uint32_t index_capacity;
	uint32_t offset;
} uniform_series_info;

typedef struct vertex_buffer {
    vector_float2 position;
} vertex_buffer;

typedef struct index_buffer {
    uint32_t index;
} index_buffer;

#ifdef __cplusplus

class vertex_container {
    
    vertex_buffer *_buffer;
    const std::size_t _capacity;
    
public :
    
    vertex_container(void *ptr, std::size_t capacity) :
    _buffer(static_cast<vertex_buffer *>(ptr)),
    _capacity(capacity)
    {}
    
    std::size_t capacity() const { return _capacity; }
    vertex_buffer& operator[](std::size_t index) { return _buffer[index]; }
    const vertex_buffer& operator[](std::size_t index) const { return _buffer[index]; }
    
};

class index_container {
    
    index_buffer *_buffer;
    const std::size_t _capacity;
    
public :
    
    index_container(void *ptr, std::size_t capacity) :
    _buffer(static_cast<index_buffer *>(ptr)),
    _capacity(capacity)
    {}
    
    std::size_t capacity() const { return _capacity; }
    index_buffer& operator[](std::size_t index) { return _buffer[index]; }
    const index_buffer& operator[](std::size_t index) const { return _buffer[index]; }
    
};

#endif

#endif /* LineEngine_common_h */
