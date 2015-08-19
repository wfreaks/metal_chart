//
//  LineEngine.metal
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/08/03.
//  Copyright © 2015年 freaks. All rights reserved.
//

#include <metal_stdlib>
#include "LineEngineShader.h"

using namespace metal;

vertex out_vertex PolyLineEngineVertexIndexed(
                                              device vertex_coord* coords [[ buffer(0) ]],
                                              device vertex_index* indices [[ buffer(1) ]],
                                              constant uniform_projection& proj [[ buffer(2) ]],
                                              constant uniform_line_attr& attr [[ buffer(3) ]],
                                              constant uniform_series_info& info [[ buffer(4) ]],
                                              uint v_id [[ vertex_id ]]
) {
	const uint vid = v_id / 6;
    const ushort index_current = indices[vid].index;
    const ushort index_next = indices[vid+1].index;
    const float2 p_current = adjustPoint( coords[index_current].position, proj );
    const float2 p_next = adjustPoint( coords[index_next].position, proj );
    
	const uchar spec = v_id % 6;
    return LineEngineVertexCore<out_vertex>(p_current, p_next, spec, attr.width, proj.physical_size);
}

vertex out_vertex PolyLineEngineVertexOrdered(
                                              device vertex_coord* coords [[ buffer(0) ]],
                                              constant uniform_projection& proj [[ buffer(1) ]],
                                              constant uniform_line_attr& attr [[ buffer(2) ]],
                                              constant uniform_series_info& info [[ buffer(3) ]],
                                              uint v_id [[ vertex_id ]]
) {
    const uint vid = v_id / 6;
    const ushort index_current = vid % info.vertex_capacity;
    const ushort index_next = (vid + 1) % info.vertex_capacity;
    const float2 p_current = adjustPoint( coords[index_current].position, proj );
    const float2 p_next = adjustPoint( coords[index_next].position, proj );
    
    const uchar spec = v_id % 6;
    return LineEngineVertexCore<out_vertex>(p_current, p_next, spec, attr.width, proj.physical_size);
}

vertex out_vertex SeparatedLineEngineVertexOrdered(
												   device vertex_coord* coords [[ buffer(0) ]],
												   constant uniform_projection& proj [[ buffer(1) ]],
												   constant uniform_line_attr& attr [[ buffer(2) ]],
												   constant uniform_series_info& info [[ buffer(3) ]],
												   uint v_id [[ vertex_id ]]
) {
	const uint idx_offset = info.offset % 2;
	const uint vid = (2 * ((v_id / 6) - idx_offset)) + idx_offset; // 質の悪い事に頂点IDだけでは奇数点から+1へ線を引くのか偶数からなのか判断ができない.
	const ushort index_current = vid % info.vertex_capacity;
	const ushort index_next = (vid + 1) % info.vertex_capacity;
	
	float2 p_current = adjustPoint( coords[index_current].position, proj );
	float2 p_next = adjustPoint( coords[index_next].position, proj );
	const float2 physical_size = proj.physical_size;
	
	const float2 length_mod = attr.length_mod;
	if(length_squared(length_mod) > 0) {
		modify_length(p_current, p_next, length_mod, physical_size);
	}
	
	const uchar spec = v_id % 6;
	return LineEngineVertexCore<out_vertex>(p_current, p_next, spec, attr.width, physical_size);
}

fragment out_fragment LineEngineFragment_WriteDepth(
                                                    const out_vertex input [[ stage_in ]],
                                                    constant uniform_projection& proj [[ buffer(0) ]],
                                                    constant uniform_line_attr& attr [[ buffer(1) ]]
) {
    const out_frag_core core = LineEngineFragmentCore_ratio(input, proj, attr.width);
    out_fragment out;
    out.color = attr.color;
    if( core.is_same_dir ) {
        out.color.a *= (attr.modify_alpha_on_edge > 0) ? core.ratio : round(core.ratio);
    }
    out.depth = (out.color.a > 0) ? 0.5 : 0;
    
	return out;
}

fragment float4 LineEngineFragment_NoDepth(
                                           const out_vertex input [[ stage_in ]],
                                           constant uniform_projection& proj [[ buffer(0) ]],
                                           constant uniform_line_attr& attr [[ buffer(1) ]]
) {
    const out_frag_core core = LineEngineFragmentCore_ratio(input, proj, attr.width);
    float4 color = attr.color;
    if( core.is_same_dir ) {
        color.a *= (attr.modify_alpha_on_edge > 0) ? core.ratio : 0;
    }
//    color.a *= saturate((!core.is_same_dir) + core.ratio ); // attr.modify_alpha_on_edge = 1 の場合に限り上の分岐の３行と等価.
    
    return color;
}


