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
    out.pos = pos * (proj.physical_size / 2);
    out.coef = value;
    return out;
}

//inline float RoundRectFragment_core(const float2 pos, const float4 rect, const float r)
//{
//    
//}

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
	
	// 以降の xMin ~ top まではベクトル演算した方が効率いいかもしれない. 微々たる差だとは思うが.
	const float xMin = (-size.x) + (padding.x + r);
	const float xMax = (+size.x) - (padding.z + r);
	const float yMin = (-size.y) + (padding.w + r);
	const float yMax = (+size.y) - (padding.y + r);
	
	const float left   = in.pos.x - xMin;
	const float right  = in.pos.x - xMax;
	const float bottom = in.pos.y - yMin;
	const float top    = in.pos.y - yMax;
	
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


struct out_vertex_bar {
    float4 position [[ position ]];
    float2 pos;
    float2 coef;
    
    float2 dir [[ flat ]];
    float2 center [[ flat ]];
    float  w   [[ flat ]];
    float  l   [[ flat ]];
};

struct uniform_bar {
    float4 color;
    float4 corner_radius;
    float  width;
};


fragment out_fragment GeneralBar_Fragment(
                                          const out_vertex_bar in [[ stage_in ]],
                                          constant uniform_bar& bar [[ buffer(0) ]],
                                          constant uniform_projection& proj [[ buffer(1) ]]
                                          )
{
    // 手順をまとめてみる. pos及びcenterはデバイス上の位置となっている. dirも同じ座標に従い、かつnormalizeされているものとする.
    // その場合直行するベクトルを求めてその２つで分解する、つまり p = a*dir + b*perp; となるa, bを求める. これは簡単で a = dot(p, dir), b = dot(p, perp)である.
    // ただしこの p は p = pos - center; である.
    // この様に分解したのち、9patchでマッピングする必要があるが、これには形状に関する情報が必要となる. これは in.w / in.l が担当するが、以下の仮定を置いている.
    // lはdir方向の長さ成分、wは垂直方向の成分、どちらもcenterから矩形の境界までの距離に相当する、つまり長さ/2, 太さ/2である.
    const float2 p = in.center - in.pos;
    const float2 perp(+in.dir.y, -in.dir.x);
    const float2 pos(dot(p, in.dir), dot(p, perp));
    
    
    
    out_fragment out;
    
    return out;
}







