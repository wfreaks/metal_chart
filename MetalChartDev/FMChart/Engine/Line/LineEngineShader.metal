//
//  LineEngine.metal
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/08/03.
//  Copyright © 2015年 freaks. All rights reserved.
//

#include "LineEngineShader.h"

vertex out_vertex_LineDash PolyLineEngineVertexOrdered(
                                                       device vertex_coord* coords [[ buffer(0) ]],
                                                       constant uniform_projection& proj [[ buffer(2) ]],
                                                       constant uniform_line_attr& attr [[ buffer(3) ]],
                                                       constant uniform_series_info& info [[ buffer(4) ]],
                                                       uint v_id [[ vertex_id ]]
) {
    const uint vid = v_id / 6;
    const uint vcap = info.vertex_capacity;
    const ushort index_current = vid % vcap;
    const ushort index_next = (vid + 1) % vcap;
    const float2 p_current = data_to_ndc( coords[index_current].position, proj );
    const float2 p_next = data_to_ndc( coords[index_next].position, proj );
    
    const uchar spec = v_id % 6;
    out_vertex_LineDash out = LineDashVertexCore<out_vertex_LineDash>(p_current, p_next, spec, attr.width, proj);
    out.depth = attr.depth;
    out.depth_add = (vid-info.offset) * 0.1 / (vcap*2);
    return out;
}

vertex out_vertex_LineDash SeparatedLineEngineVertexOrdered(
                                                            device vertex_coord* coords [[ buffer(0) ]],
                                                            constant uniform_projection& proj [[ buffer(1) ]],
                                                            constant uniform_line_attr& attr [[ buffer(2) ]],
                                                            constant uniform_series_info& info [[ buffer(3) ]],
                                                            uint v_id [[ vertex_id ]]
) {
	const uint idx_offset = info.offset % 2;
	const uint vid = (2 * ((v_id / 6) - idx_offset)) + idx_offset; // 質の悪い事に頂点IDだけでは奇数点から+1へ線を引くのか偶数からなのか判断ができない.
	const uint vcap = info.vertex_capacity;
	const ushort index_current = vid % vcap;
	const ushort index_next = (vid + 1) % vcap;
	
	float2 p_current = data_to_ndc( coords[index_current].position, proj );
	float2 p_next = data_to_ndc( coords[index_next].position, proj );
	const float2 physical_size = proj.physical_size;
	
	const float2 length_mod = attr.length_mod;
	if(length_squared(length_mod) > 0) {
		modify_length(p_current, p_next, length_mod, physical_size);
	}
	
	const uchar spec = v_id % 6;
	return LineDashVertexCore<out_vertex_LineDash>(p_current, p_next, spec, attr.width, proj);
}

template <typename InputType, typename ParamType>
inline float LineDashFragmentExtra(thread const InputType input, constant ParamType& conf)
{
    const float _w = 1/conf.width;
    const float _lr = conf.length_repeat * _w; // 実際のスケールとしては、座標変換的には1/2倍のものになる.
    const float lr = ((_lr > 0) * _lr) + ((_lr <= 0) * input.l_scaled);
    const float l = lr + (conf.length_space * _w) + 1;
    const float offset_dash = l * conf.repeat_anchor_dash; // %をとる前に引く値、スケールがリピートサイズになる.
    const float offset_line = input.l_scaled * conf.repeat_anchor_line; // 同上、ただしスケールは線全体.
    float2 pos = input.position_scaled;
    const float y2 = ((pos.y + offset_dash - offset_line) / (2*l)) + 0.5;
    const float y3 = (2*l) * ((y2 - floor(y2)) - 0.5);
    const float y4 = ((y3 >= lr) * (y3 - lr)) + ((y3 <= -lr) * (y3 + lr));
    pos.y = y4;
    
    const float distance_from_circle_in_px = (input.scale * (length(pos) - 1)) + 0.5;
    return saturate(1.0 - distance_from_circle_in_px);
}

fragment out_fragment_depthGreater LineEngineFragment_NoOverlay(
                                                                const out_vertex_LineDash input [[ stage_in ]],
                                                                constant uniform_projection& proj [[ buffer(0) ]],
                                                                constant uniform_line_attr& attr [[ buffer(1) ]]
) {
    const float ratio = LineDashFragmentCore(input);
    out_fragment_depthGreater out;
    out.color = attr.color;
    out.color.a *= attr.alpha * round(ratio);
    out.depth = (out.color.a > 0) * input.depth;
    
	return out;
}

fragment out_fragment_depthGreater LineEngineFragment_Overlay(
                                                              const out_vertex_LineDash input [[ stage_in ]],
                                                              constant uniform_projection& proj [[ buffer(0) ]],
                                                              constant uniform_line_attr& attr [[ buffer(1) ]]
) {
    const float ratio = LineDashFragmentCore(input);
    out_fragment_depthGreater out;
    out.color = attr.color;
    out.color.a *= attr.alpha * ratio;
    out.depth = (out.color.a > 0) * (input.depth + input.depth_add);
    
    return out;
}

fragment out_fragment_depthGreater DashedLineFragment_NoOverlay(
                                                                const out_vertex_LineDash input [[ stage_in ]],
                                                                constant uniform_projection& proj [[ buffer(0) ]],
                                                                constant uniform_line_attr& attr [[ buffer(1) ]]
                                                                ) {
    const float ratio = LineDashFragmentCore(input);
    const float ratio_b = LineDashFragmentExtra(input, attr);
    out_fragment_depthGreater out;
    out.color = attr.color;
    out.color.a *= attr.alpha * round(min(ratio, ratio_b));
    out.depth = (out.color.a > 0) * input.depth;
    
    return out;
}

fragment out_fragment_depthGreater DashedLineFragment_Overlay(
                                                              const out_vertex_LineDash input [[ stage_in ]],
                                                              constant uniform_projection& proj [[ buffer(0) ]],
                                                              constant uniform_line_attr& attr [[ buffer(1) ]]
                                                              ) {
    const float ratio = LineDashFragmentCore(input);
    const float ratio_b = LineDashFragmentExtra(input, attr);
    out_fragment_depthGreater out;
    out.color = attr.color;
    out.color.a *= attr.alpha * min(ratio, ratio_b);
    out.depth = (out.color.a > 0) * (input.depth + input.depth_add);
    
    return out;
}


