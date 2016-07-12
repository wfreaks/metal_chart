//
//  Lines_common.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/03.
//  Copyright © 2015年 freaks. All rights reserved.
//

#ifndef Lines_common_h
#define Lines_common_h

#include <simd/simd.h>

/**
 * See FMUniformLineAttributes (LineBuffers.h) for details.
 */

typedef struct {
	vector_float4 color;
	float width;
	float length_repeat;
	float length_space;
	float repeat_anchor_line;
	float repeat_anchor_dash;
} uniform_line_attr;


/**
 * See FMUniformLineConf (LineBuffer.h) for details.
 */

typedef struct {
	float alpha;
	float depth;
	uint8_t modify_alpha_on_edge;
} uniform_line_conf;


/**
 * See FMUniformAxisConfiguration (LineBuffer.h) for details.
 */

typedef struct uniform_axis_configuration {
	float		   axis_anchor_value_data;
	float		   axis_anchor_value_ndc;
	float		   tick_anchor_value;
	float		   tick_interval_major;
	
	uint8_t		 dimIndex;
	uint8_t		 minor_ticks_per_major;
	uint8_t		 max_major_ticks;
} uniform_axis_configuration;


/**
 * See FMUniformAxisAttributes (LineBuffer.h) for details.
 */

typedef struct uniform_axis_attributes {
	vector_float4   color;
	vector_float2   length_mod;
	float		   line_length;
	float		   width;
} uniform_axis_attributes;


/**
 * See FMUniformGridAttributes (LineBuffer.h) for details.
 */

typedef struct uniform_grid_attributes {
	vector_float4 color;
	float width;
	
	float anchor_value;
	float interval;
	float depth;
	float length_repeat;
	float length_space;
	float repeat_anchor_line;
	float repeat_anchor_dash;
	uint8_t dimIndex;
} uniform_grid_attributes;

#endif /* Lines_common_h */
