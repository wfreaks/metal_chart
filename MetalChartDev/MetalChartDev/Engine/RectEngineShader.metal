//
//  RectEngineShader.metal
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/08/26.
//  Copyright © 2015年 freaks. All rights reserved.
//

#include "Shader_common.h"

struct out_vertex {
    float4 position [[ position ]];
    float2 pos;
    float2 coef;
};

struct out_fragment {
    float4 color [[ color(0) ]];
};

struct uniform_plot_rect {
    float4 color;
    float4 corner_radius; // 解釈は(x, y, z, w) = (lt, rt, lb, rb);
};

vertex out_vertex PlotRect_Vertex(
                                  constant uniform_plot_rect&  rect [[ buffer(0) ]],
                                  constant uniform_projection& proj [[ buffer(1) ]],
                                  uint v_id [[ vertex_id ]]
                                  )
{
	const uint spec = v_id % 4;
	const bool is_right = ((spec % 2) == 1);
	const bool is_top = ((spec / 2) == 0);
	const float2 value = float2( (2*(is_right))-1, (2*(is_top))-1 ); // (±1, ±1)へマッピング.
	const float2 pos = adjustPoint(value, proj);
    out_vertex out;
	out.position = float4(pos.x, pos.y, 0, 1.0);
    out.pos = pos;
    out.coef = value;
    return out;
}

fragment out_fragment PlotRect_Fragment(
										const out_vertex in [[ stage_in ]],
										constant uniform_plot_rect& rect  [[ buffer(0) ]],
										constant uniform_projection& proj [[ buffer(1) ]]
										)
{
	const float2 size = proj.physical_size / 2;
	const float4 padding = proj.rect_padding;
    const float2 signs = sign(in.coef);
    const uchar idx_corner = (signs.x > 0) + (2 * (signs.y <= 0));
    const float r = rect.corner_radius[idx_corner];
	const float2 pos = in.pos * size; // position in view, origin at center, dpi scale.
	
	// 以降の xMin ~ top まではベクトル演算した方が効率いいかもしれない. 微々たる差だとは思うが.
	const float xMin = (-size.x) + (padding.x + r);
	const float xMax = (+size.x) - (padding.z + r);
	const float yMin = (-size.y) + (padding.w + r);
	const float yMax = (+size.y) - (padding.y + r);
	
	const float left   = pos.x - xMin;
	const float right  = pos.x - xMax;
	const float bottom = pos.y - yMin;
	const float top    = pos.y - yMax;
	
	const float x = ((left   < 0) * left  ) + ((right > 0) * right);
	const float y = ((bottom < 0) * bottom) + ((top   > 0) * top  );
	
	const float2 mapped_pos = float2(x, y);
	const float dist_from_circle_in_px = ( (length(mapped_pos) - r) * proj.screen_scale ) + 0.5;
	const float ratio = saturate(saturate(1 - dist_from_circle_in_px) + (r <= 0)); // r<=0の時には常にalpha値に変更なしにする.
	
    out_fragment out;
    out.color = rect.color;
	out.color.a *= ratio;
	
    return out;
}
