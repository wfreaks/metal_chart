//
//  Rect_common.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/26.
//  Copyright © 2015年 freaks. All rights reserved.
//

#ifndef Rect_common_h
#define Rect_common_h

#include <simd/simd.h>

#ifdef __cplusplus

using namespace simd;

#endif

struct uniform_plot_rect {
	vector_float4 color;
	vector_float4 corner_radius;
	float depth_value;
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

struct uniform_rect_attr {
	vector_float4 color;
};

#ifdef __OBJC__

typedef struct uniform_plot_rect uniform_plot_rect;
typedef struct uniform_bar_conf uniform_bar_conf;
typedef struct uniform_bar_attr uniform_bar_attr;
typedef struct uniform_rect_attr uniform_rect_attr;

#endif

#endif /* Rect_common_h */
