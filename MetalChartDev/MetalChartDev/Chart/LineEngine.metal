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
};

struct vertex_coord {
	float2 position;
};

struct vertex_index {
	ushort index;
};

struct uniform_projection {
	float2 view_size;
	float2 range_lb;
	float2 range_rt;
};

struct uniform_line_attr {
	float width;
};

struct out_fragment {
	float4 color [[ color ]];
	float depth [[ ]]
};

vertex out_vertex LineEngineIndexed(
									device vertex_coord* coords [[ buffer(0) ]],
									device vertex_index* indices [[ buffer(1) ]],
									constant uniform_projection& proj,
									constant uniform_line_attr& attr,
									uint v_id [[ vertex_id ]]
									)
{
	const uint vid = v_id / 6;
	const uchar spec = v_id % 6;
	const uchar along = 2 * (spec % 2) - 1; // 偶数で-1, 奇数で1にする.
	const uchar perp = (2 * min(1, spec % 5)) - 1; // 0か1の時に-1, 1~4の時は1にする.
	const ushort index_current = indices[vid];
	const ushort index_next = indices[vid+1];
	const float2 p_current = coords[index_current];
	const float2 p_next = coords[index_next];
	const float2 diff_along = along * attr.width * normalize(p_next - p_current);
	const float2 diff_perp = float2( - perp * diff_along.y, perp * diff_along.x );
	const float pos = (along == 1) ? p_next : p_current;
	
	out_vertex out;
	out.position.xy = pos + diff_along + diff_perp;
	return out;
}

fragment

