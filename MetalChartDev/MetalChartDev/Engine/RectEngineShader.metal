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
};

struct out_fragment {
    float4 color [[ color(0) ]];
};

struct uniform_plot_rect {
    float4 color;
    float  corner_radius;
};

vertex out_vertex PlotRect_Vertex(
                                  constant uniform_plot_rect&  rect [[ buffer(0) ]],
                                  constant uniform_projection& proj [[ buffer(1) ]],
                                  uint v_id [[ vertex_id ]]
                                  )
{
	const uint spec = v_id % 6;
	const bool is_right = ((spec % 2) == 1);
	const bool is_top = ((spec == 2) | (spec == 4) | (spec == 5)); // あんま綺麗じゃないけどパフォーマンス的問題はない...まぁコンパイラが勝手にbranch発行してドツボにはまってなければの話だけど.
	const float2 value = float2( (2*(is_right))-1, (2*(is_top))-1 ); // (±1, ±1)へマッピング.
	const float2 pos = adjustPoint(value, proj);
    out_vertex out;
	out.position = float4(pos.x, pos.y, 0, 1.0);
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
	const float r = rect.corner_radius;
	const float2 pos = in.position.xy * size; // position in view, origin at center, dpi scale.
	
	// 以降の xMin ~ top まではベクトル演算した方が効率いいかもしれない. 微々たる差だとは思うが.
	const float xMin = (-size.x) + (padding.x + r);
	const float xMax = (+size.x) - (padding.z + r);
	const float yMin = (-size.y) + (padding.y + r);
	const float yMax = (+size.y) - (padding.w + r);
	
	const float left   = pos.x - xMin;
	const float right  = pos.x - xMax;
	const float bottom = pos.y - yMin;
	const float top    = pos.y - yMax;
	
	const float x = ((left   < 0) * left  ) + ((right > 0) * right);
	const float y = ((bottom < 0) * bottom) + ((top   > 0) * top  );
	
	const float2 mapped_pos = float2(x, y);
	const float dist_from_circle_in_px = ( (length(mapped_pos) - r) * proj.screen_scale ) + 0.5;
	const float ratio = saturate(1 - dist_from_circle_in_px);
	
    out_fragment out{rect.color};
	out.color.a *= ratio;
	
    return out;
}
