//
//  circle_shared.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/11/18.
//  Copyright © 2015年 freaks. All rights reserved.
//

#ifndef circle_shared_h
#define circle_shared_h

#include <simd/simd.h>

#ifdef __cplusplus

using namespace simd;

#endif

struct pie_conf {
	float  radius_inner;
	float  radius_outer;
	float  radian_offseet;
	float  value_total;
};

struct pie_attr {
	vector_float4 color;
};

struct indexed_value_float {
	float value;
	uint32_t idx;
};

#ifdef __OBJC__

typedef struct pie_conf uniform_pie_configuration;

typedef struct pie_attr uniform_pie_attributes ;

typedef struct indexed_value_float indexed_value_float;

#endif

#endif /* circle_shared_h */
