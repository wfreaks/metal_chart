//
//  Rect_common.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/26.
//  Copyright © 2015 Keisuke Mori. All rights reserved.
//

#ifndef Rect_common_h
#define Rect_common_h

#include <simd/simd.h>

#ifdef __cplusplus

using namespace simd;

#endif

struct uniform_plot_rect {
	vector_float4 color_start;
	vector_float4 color_end;
	vector_float2 pos_start;
	vector_float2 pos_end;
	float depth_value;
	float corner_radius;
};

struct uniform_bar_conf {
	vector_float2 dir;
	vector_float2 anchor_point;
	float		 depth_value;
};

struct uniform_bar_attr {
	vector_float4 color;
	vector_float4 corner_radius;
	float		 width;
};

#ifdef __OBJC__

typedef struct uniform_plot_rect uniform_plot_rect;
typedef struct uniform_bar_conf uniform_bar_conf;
typedef struct uniform_bar_attr uniform_bar_attr;
typedef struct uniform_rect_attr uniform_rect_attr;

#endif

#endif /* Rect_common_h */
