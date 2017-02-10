//
//  LineAreaShader.metal
//  MetalChartDev
//
//  Created by Keisuke Mori on 2017/01/29.
//  Copyright © 2017年 freaks. All rights reserved.
//

#include "../Base/Shader_common.h"
#include "Line_common.h"

struct out_vertex_LineArea {
	float4 position_ndc [[ position ]];
	half  a_pos;
	half  a_neg;
	half  coef;
};


inline float a_grad(constant gradient_conf& g, float2 pos) {
	const float2 grad_p = g.pos_end - g.pos_start;
	const float grad_l = dot(grad_p, grad_p);
	const float grad_d = dot(grad_p, (pos - g.pos_start));
	return grad_d / grad_l;
}

vertex out_vertex_LineArea LineAreaVertex(
										  device   vertex_float2*             coords [[ buffer(0) ]],
										  constant uniform_line_area_conf&      conf [[ buffer(1) ]],
										  constant uniform_line_area_attr&      attr [[ buffer(2) ]],
										  constant uniform_projection_cart2d&   proj [[ buffer(3) ]],
										  constant uniform_series_info&         info [[ buffer(4) ]],
										  const    uint                         v_id [[ vertex_id ]]
										  )
{
	const uint vid = v_id / 6;
	const uint vcap = info.vertex_capacity;
	const uchar spec = v_id % 6;
	const bool next = spec % 2;
	const bool edge = ((spec % 2 == 0) ^ (spec % 5 == 0));
	const ushort index = (vid+next) % vcap;
	
	const float2 a_data = (conf.anchor_data) ? conf.anchor : semi_ndc_to_data(conf.anchor, proj);
	const float2 dir = normalize(conf.direction);
	float2 p_data = coords[index].position;
	const float2 diff_data = (p_data - a_data);
	p_data = (edge) ? (a_data + (dot(dir, diff_data) * dir)) : p_data;
	const float2 p_ndc = data_to_ndc(p_data, proj);
	const float2 p_ndc_semi = data_to_semi_ndc(p_data, proj);
	const float2 pos = (conf.grad_pos_data) ? p_data : p_ndc_semi;
	
	out_vertex_LineArea out;
	out.position_ndc = float4(p_ndc, 0, 1);
	out.a_pos = half(a_grad(attr.grads[0], pos));
	out.a_neg = half(a_grad(attr.grads[1], pos));
	out.coef = half((diff_data.y * dir.x) - (dir.y * diff_data.x));
	
	return out;
}


fragment out_fragment_h_depthGreater LineAreaFragment(
												   const    out_vertex_LineArea                  input [[ stage_in  ]],
												   constant uniform_line_area_conf&               conf [[ buffer(0) ]],
												   constant uniform_line_area_attr&               attr [[ buffer(1) ]]
												   )
{
	const bool positive = (input.coef > 0);
	constant gradient_conf& g = attr.grads[!positive];
	const half a = saturate(positive ? input.a_pos : input.a_neg);
	
	out_fragment_h_depthGreater out;
	out.color = mix(half4(g.color_start), half4(g.color_end), a) * half4(1, 1, 1, conf.opacity);
	out.depth = conf.depth;
	
	return out;
}

