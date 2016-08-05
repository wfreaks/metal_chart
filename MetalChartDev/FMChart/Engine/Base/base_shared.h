//
//  base_shared.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/11/17.
//  Copyright © 2015 Keisuke Mori. All rights reserved.
//

#ifndef base_shared_h
#define base_shared_h

#include <simd/simd.h>

#ifdef __cplusplus

using namespace simd;

#endif

/**
 * a struct of a non-attributed 2-component data.
 */

typedef struct {
	vector_float2 position;
} vertex_float2;

/**
 * a struct of an attributed 1-component data.
 * idx (attributes index) specifies to which group the data point belongs, and which attribute set the point uses for drawing.
 */

typedef struct {
	float value;
	uint32_t idx;
} indexed_float;

/**
 * a struct of an attributed 2-component data.
 * idx (attributes index) specifies to which group the data point belongs, and which attribute set the point uses for drawing.
 */

typedef struct {
	vector_float2 value;
	uint32_t idx;
} indexed_float2;

/**
 * a struct which represents a mapping from a 2-dimensional cartesian space to a view space.
 * see Shader_common.h and FMUniformProjectionCartesian2D (Buffers.h) for details.
 */

typedef struct {
	vector_float2 origin;
	vector_float2 value_scale;
	vector_float2 value_offset;
	
	vector_float2 physical_size;
	vector_float4 rect_padding;
	float  screen_scale;
} uniform_projection_cart2d;


/**
 * a struct which contains informaion of data series (FMSeries object) and its underlying buffer (capacity).
 * see FMUniformSeriesInfo (Buffers.h) for details.
 */

typedef struct {
	uint32_t vertex_capacity;
	uint32_t index_capacity;
	uint32_t offset;
} uniform_series_info;

/**
 * a struct which represents a mapping from a 2-dimensional polar space to a view space.
 * all angular expression are in radian.
 * if distance_in_view(p, center) = x logical pixels where p = (θ, r), then r = radius_scale * x.
 * so basically p will be placed at the point with offset (scale*r*cos(θ), -scale*r*sin(θ)) from center (r=0) in view coordinates.
 *
 * see Shader_common.h and FMUniformProjectionPolar (Buffers.h) for details.
 */

typedef struct uniform_projection_polar {
	vector_float2 origin_ndc;
	vector_float2 origin_offset;
	float  radian_offset;
	float  radius_scale;
	
	vector_float2 physical_size;
	vector_float4 rect_padding;
	float screen_scale;
} uniform_projection_polar;


#endif /* base_shared_h */
