//
//  Circle.metal
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/11/10.
//  Copyright © 2015年 freaks. All rights reserved.
//

#include "../Base/Shader_common.h"

struct uniform_pie_global_attr {
	float  radius_inner;
	float  radius_outer;
	float  radian_offseet;
	float  value_total;
};

struct attri_pie {
	float4 color;
};

struct out_vertex_pie {
	float4 position [[ position ]];
	float4 color;
	float2 pos_view; // centerからのviewスケールでのdiff.
	float  depth;
};

inline float ratio_pie(const float inner, const float outer, const float dist, const float screen_scale)
{
	const float2 diff_px = (screen_scale * float2(dist-inner, outer-dist)) + 0.5;
	const float2 sat = saturate(diff_px);
	return (sat.x * sat.y);
}

vertex out_vertex_pie PieVertex(device		uint*							indices [[ buffer(0) ]],
								device		float*							values	[[ buffer(1) ]],
								device		attr_pie*						attrs   [[ buffer(2) ]],
								constant	uniform_projection_polar&		proj	[[ buffer(3) ]],
								constant	uniform_pie_global_attr&		attr	[[ buffer(4) ]],
								const uint									vid_raw [[ vertex_id ]]
								)
{
	// 頂点順序は, center -> left -> right / left -> right -> out
	const uint vid = vid_raw / 6;
	const uchar spec = vid_raw % 6;
	const uint idx_current = indices[vid], idx_next = indices[vid]
	const float v_current = values[indices[vid]];
	const float
	
	out_vertex_pie out;
	
	return out;
}

fragment out_fragment_depthGreater PieFragment(const	out_vertex_pie				input	[[ stage_in  ]],
											   constant uniform_projection_polar&	proj	[[ buffer(0) ]],
											   constant uniform_pie_global_attr&	attr	[[ buffer(1) ]]
											   )
{
	// 座業変換はvshader、こっちは特定の切り方をされた時、その距離を求めて、適切なalphaを求めるという感じ.
	const float dist = length(input.pos_view);
	out_fragment_depthGreater out;
	const float ratio = ratio_pie(attr.radius_inner, attr.radius_outer, dist, proj.screen_scale);
	out.color = input.color;
	out.color.a *= ratio;
	out.depth = (ratio > 0) * input.depth;
	return out;
}

