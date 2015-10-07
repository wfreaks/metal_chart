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


