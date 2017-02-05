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
	float2 pos_ndc;
	float2 pos_data;
};


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
	p_data = (edge) ? (a_data + (dot(dir, (p_data - a_data)) * dir)) : p_data;
	const float2 p_ndc = data_to_ndc(p_data, proj);
	
	out_vertex_LineArea out;
	out.position_ndc = float4(p_ndc, 0, 1);
	out.pos_data = p_data;
	out.pos_ndc = data_to_semi_ndc(p_data, proj);
	
	return out;
}


fragment out_fragment_depthGreater LineAreaFragment(
												   const    out_vertex_LineArea                  input [[ stage_in  ]],
												   constant uniform_line_area_conf&               conf [[ buffer(0) ]],
												   constant uniform_line_area_attr&               attr [[ buffer(1) ]]
												   )
{
	float coef = 1;
	{
		const float2 pos_cond = (conf.cond_pos_data) ? input.pos_data : input.pos_ndc;
		const float2 p1 = attr.cond_end - attr.cond_start;
		const float l = dot(p1, p1);
		const float d = dot(p1, (pos_cond - attr.cond_start));
		coef = step(0, d) * step(d, l);
	}
	
	float a;
	{
		const float2 pos_grad = (conf.grad_pos_data) ? input.pos_data : input.pos_ndc;
		const float2 grad_p = attr.pos_end - attr.pos_start;
		const float grad_l = dot(grad_p, grad_p);
		const float grad_d = dot(grad_p, (pos_grad - attr.pos_start));
		a = saturate(grad_d / grad_l);
	}
	
	out_fragment_depthGreater out;
	out.color = mix(attr.color_start, attr.color_end, a);
	out.color.a *= coef * conf.opacity;
	out.depth = conf.depth;
	
	return out;
}

