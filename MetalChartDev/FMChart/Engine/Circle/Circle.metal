//
//  Circle.metal
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/11/10.
//  Copyright © 2015年 freaks. All rights reserved.
//

#include "../Base/Shader_common.h"

#define M_PI  3.14159265358979323846264338327950288

struct uniform_pie_global_attr {
	float  radius_inner;
	float  radius_outer;
	float  radian_offseet;
	float  value_total;
};

struct attr_pie {
	float4 color;
};

struct out_vertex_pie {
	float4 position   [[ position ]];
	float  point_size [[ point_size ]];
	float  psize;
};

inline float ratio_pie(const float inner, const float outer, const float dist, const float screen_scale)
{
	const float2 diff_px = (screen_scale * float2(dist-inner, outer-dist)) + 0.5;
	const float2 sat = saturate(diff_px);
	return (sat.x * sat.y);
}

vertex out_vertex_pie PieVertex(
								constant	uniform_projection_polar&		proj	[[ buffer(0) ]]
								)
{
	out_vertex_pie out;
	out.position = float4(0, 0, 0, 1);
	out.point_size = 400;
	out.psize = 20;
	
	return out;
}

fragment out_fragment PieFragment(
								  out_vertex_pie input [[ stage_in ]],
								  const float2 pos_coord [[ point_coord ]],
								  constant uniform_projection_polar&	proj	[[ buffer(0) ]],
								  constant const float * values [[ buffer(1) ]],
								  constant const float4 * colors [[ buffer(2) ]],
								  constant float& total_value [[ buffer(3) ]],
								  constant int&   count [[ buffer(4) ]]
								  )
{
//	const float dist = length(input.pos_view);
//	out_fragment_depthGreater out;
//	const float ratio = ratio_pie(attr.radius_inner, attr.radius_outer, dist, proj.screen_scale);
//	out.color = input.color;
//	out.color.a *= ratio;
//	out.depth = (ratio > 0) * input.depth;
//	return out;
	const float2 pos = (2 * pos_coord) - 1;
	const float coef = 2 * M_PI / total_value;
	float radian = atan2(-pos.y, pos.x);
	radian += (radian < 0) * 2 * M_PI;
	int idx = 0;
	const int c = 3;
	for(int i = 0; i < c; ++i) {
		const float r = values[i] * coef;
		idx += (radian >= r);
		radian -= ((radian >= r) * r);
	}
	out_fragment out;
	
	out.color = colors[idx];
	out.color.a *= (length(pos) < 1);
	
	return out;
}

