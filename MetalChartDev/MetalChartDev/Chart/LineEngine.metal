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
	float2 view_size;
	float2 range_lb;
	float2 range_rt;
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
	const float2 diff_along = along * attr.width * normalize(vec_diff);
	const float2 diff_perp = float2( - perp * diff_along.y, perp * diff_along.x );
	const float2 pos = (along == 1) ? p_next : p_current;

	out_vertex out;
    out.pos = pos + diff_along + diff_perp;
    out.position.xy = out.pos;
    out.position.z = 0.5;
    out.position.w = 1;
	out.mid_pos = (p_current + p_next) / 2;
	out.vec_dir = vec_diff;
	out.coef = (float)along;
    
//    out.position.x = ( (2 * ((v_id  ) % 2)) - 1.0 ) * 0.5;
//    out.position.y = ( (2 * ((v_id/2) % 2)) - 1.0 ) * 0.5;
    
    return out;
}

fragment float4 LineEngineFragment(
								   out_vertex input [[stage_in]],
								   constant uniform_line_attr& attr [[ buffer(0)]]
)
{
	const float2 pos = input.pos;
	const float2 base = input.mid_pos + (input.coef >= 0 ? +input.vec_dir : -input.vec_dir);
	const float2 dir = base - input.mid_pos;
	const float2 diff = pos - base;
	const bool is_same_dir = (dot(diff, dir) > 0);
	const bool is_not_in_circle = (length(diff) >= attr.width);
	return (is_same_dir && is_not_in_circle) ? float4(0) : attr.color;
//    return float4 (1, 1, 0, 1);
}

