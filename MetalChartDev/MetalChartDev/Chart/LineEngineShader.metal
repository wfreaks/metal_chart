//
//  LineEngine.metal
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/08/03.
//  Copyright © 2015年 freaks. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct out_vertex {
	float4 position [[ position ]];
    float2 mid_pos [[ flat ]];
    float2 vec_dir [[ flat ]];
    float2 pos;
	float  coef;
};

struct vertex_coord {
	float2 position;
};

struct vertex_index {
	uint index;
};

struct uniform_projection {
	float2 physical_size;
	float  screen_scale;
    
    float2 origin;
    float2 value_scale;
};

struct uniform_line_attr {
	float width;
	float4 color;
};

struct uniform_series_info {
    ushort capacity;
    ushort offset;
};

vertex out_vertex LineEngineVertexIndexed(
									device vertex_coord* coords [[ buffer(0) ]],
									device vertex_index* indices [[ buffer(1) ]],
									constant uniform_projection& proj [[ buffer(2) ]],
									constant uniform_line_attr& attr [[ buffer(3) ]],
                                    constant uniform_series_info& info [[ buffer(4) ]],
									uint v_id [[ vertex_id ]]
									)
{
	const uint vid = v_id / 6;
	const uchar spec = v_id % 6;
	const char along = (2 * (spec % 2)) - 1; // 偶数で-1, 奇数で1にする.
	const char perp = (2 * min(1, spec % 5)) - 1; // 0か1の時に-1, 1~4の時は1にする.
	const ushort index_current = indices[vid].index;
	const ushort index_next = indices[vid+1].index;
	const float2 p_current = coords[index_current].position;
	const float2 p_next = coords[index_next].position;
	const float2 vec_diff = (p_next - p_current) / 2;
	const float2 size = proj.physical_size / 2;
	const float w = attr.width / 2;
	const float2 diff_along_physical = along * w * normalize(vec_diff*size) ;
	const float2 diff_perp_physical = float2( - perp * diff_along_physical.y, perp * diff_along_physical.x );
	const float2 diff_along = diff_along_physical / size;
	const float2 diff_perp = diff_perp_physical / size;
	const float2 pos = (along == 1) ? p_next : p_current;

	out_vertex out;
    out.pos = pos + (diff_along + diff_perp);
    out.position.xy = out.pos;
    out.position.z = 0.5;
    out.position.w = 1;
	out.mid_pos = (p_current + p_next) / 2;
	out.vec_dir = vec_diff;
	out.coef = (float)along;
    
    return out;
}

fragment float4 LineEngineFragment(
								   out_vertex input [[stage_in]],
								   constant uniform_projection& proj [[ buffer(0) ]],
								   constant uniform_line_attr& attr [[ buffer(1) ]]
)
{
	const float2 pos = input.pos;
	const float2 size = proj.physical_size / 2;
	const float2 base = input.mid_pos + (input.coef >= 0 ? +input.vec_dir : -input.vec_dir);
	const float2 dir = (base - input.mid_pos) * size;
	const float2 diff = (pos - base) * size;
	const float w = attr.width / 2;
	const float distance_from_circle_in_px = ((length(diff) - w) * proj.screen_scale) + 0.5; // ピクセル中心にposがあるので、alpha値が変動するのは距離(px)が[-0.5,+0.5]の間になる.
	const bool is_same_dir = (dot(diff, dir) >= 0);
	float4 color = attr.color;
    
	if(is_same_dir) color.a *= max(0.0, min(1.0, 1.0-distance_from_circle_in_px));
    
	return color;
}

