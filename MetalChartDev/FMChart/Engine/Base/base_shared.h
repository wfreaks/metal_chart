//
//  base_shared.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/11/17.
//  Copyright © 2015年 freaks. All rights reserved.
//

#ifndef base_shared_h
#define base_shared_h

#include <simd/simd.h>

#ifdef __cplusplus

using namespace simd;

#endif

struct vertex_coord {
	vector_float2 position;
};

struct vertex_index {
	uint32_t index;
};

// 主に属性付きの値(色などの設定を変える)を表示する際に使う.
// 別々のパラメータとしてもよいが、数の一致や扱い方の煩雑さなどからこちらの方が使い易いと思う.
struct indexed_value_float {
	float value;
	uint32_t idx;
};

struct indexed_value_float2 {
	vector_float2 value;
	uint32_t idx;
};

struct uniform_projection_cart2d {
	vector_float2 origin;
	vector_float2 value_scale;
	vector_float2 value_offset;
	
	vector_float2 physical_size;
	vector_float4 rect_padding;
	float  screen_scale;
};

struct uniform_series_info {
	uint32_t vertex_capacity;
	uint32_t index_capacity;
	uint32_t offset;
};

// 角度表現はすべてradianで統一する.
// r軸のスケールは、基本が1dip($(scale) pixels)が1に相当、そこにradius_scaleをかけたものとする.
typedef struct uniform_projection_polar {
	vector_float2 origin_ndc;
	vector_float2 origin_offset;
	float  radian_offset;
	float  radius_scale;
	
	vector_float2 physical_size;
	vector_float4 rect_padding;
	float screen_scale;
} uniform_projection_polar;


#ifdef __OBJC__

typedef struct vertex_coord vertex_buffer;
typedef struct vertex_index index_buffer;
typedef struct uniform_series_info uniform_series_info;

typedef struct uniform_projection_cart2d uniform_projection_cart2d;
typedef struct uniform_projection_polar uniform_projection_polar;

typedef struct indexed_value_float indexed_value_float;
typedef struct indexed_value_float2 indexed_value_float2;

#endif


#endif /* base_shared_h */
