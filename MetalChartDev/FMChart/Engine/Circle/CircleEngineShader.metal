//
//  Circle.metal
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/11/10.
//  Copyright © 2015年 freaks. All rights reserved.
//

#include "../Base/Shader_common.h"
#include "circle_shared.h"

#define M_PI  3.14159265358979323846264338327950288

struct out_vertex_arc {
	float4 position	[[ position ]];
	float4 color;
	float2 diff;
	float  rad_inner;
	float  rad_outer;
};

inline float ratio_arc(const float inner, const float outer, const float dist, const float screen_scale)
{
	const float2 diff_px = (screen_scale * float2(dist-inner, outer-dist)) + 0.5;
	const float2 sat = saturate(diff_px);
	return (sat.x * sat.y);
}

vertex out_vertex_arc ArcContinuosVertex(
								device		indexed_value_float*			values	[[ buffer(0) ]],
								constant	arc_conf&						conf	[[ buffer(1) ]],
								constant	arc_attr*						attrs	[[ buffer(2) ]],
								constant	uniform_projection_polar&		proj	[[ buffer(3) ]],
								const		uint							vid_raw	[[ vertex_id ]]
								)
{
	const uint vid = vid_raw % 3;
	const uint arc_id = vid_raw / 12;
	const uint subarc_id = (vid_raw % 12) / 3;
	
	const float t1 = values[arc_id].value, t2 = values[arc_id+1].value;
	const uint  idx = values[arc_id+1].idx;
	const arc_attr attr = attrs[idx];
	const float theta = min(2*M_PI, t2-t1);
	const float theta_8 = theta / 8;
	const float ro = max(conf.radius_outer, attr.radius_outer);
	const float ri = max(conf.radius_inner, attr.radius_inner);
	const float r_subarc = ro / cos(theta_8);
	const float t = t1 + (2*theta_8*(subarc_id + (vid == 2)));
	const float r = (vid > 0) * r_subarc;
	const float2 origin = float2(0, 0);//polar_to_ndc(float2(0, 0), proj);
	const float2 pos = polar_to_ndc(float2(r, t), proj);
	out_vertex_arc out;
	out.position = float4(pos, 0, 1);
	out.diff = 0.5 * proj.physical_size * (pos - origin);
	out.color = attr.color;
	out.rad_outer = ro;
	out.rad_inner = ri;
	return out;
}

fragment out_fragment ArcFragment(
								  out_vertex_arc input [[ stage_in ]],
								  constant	uniform_projection_polar&		proj	[[ buffer(0) ]]
								  )
{
	out_fragment out;
	
	out.color = input.color;
	const float rs = proj.radius_scale;
	const float ro = input.rad_outer * rs;
	const float ri = input.rad_inner * rs;
	const float l = length(input.diff);
	const float ratio = ratio_arc(ri, ro, l, proj.screen_scale);
	out.color.a *= ratio;
	
	return out;
}

