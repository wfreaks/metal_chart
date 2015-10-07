//
//  LineEngineShader.h
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/08/17.
//  Copyright © 2015年 freaks. All rights reserved.
//

#ifndef LineEngineShader_h
#define LineEngineShader_h

#include "../Base/Shader_common.h"

struct uniform_line_attr {
    float4 color;
    float2 length_mod;
    float width;
    float depth;
    float alpha;
    float length_repeat;
    float length_space;
    float repeat_anchor_line;
    float repeat_anchor_dash;
    uchar modify_alpha_on_edge;
};

inline void modify_length(thread float2& start, thread float2& end, float2 modifier, float2 phy_size)
{
    const float2 mid = (start + end) / 2;
    const float2 v = normalize(end-start) / phy_size;
    start = mid + (modifier.x * v);
    end = mid + (modifier.y * v);
}

// 10/07に線のシェーダをオーバホール開始. 段階的に置き換えていく.

// 基本的な考え方は、線の中央を原点、view座標における進行方向単位ベクトルが[0, 1]となるような座標変換をかけた際に、
// position_scaled の xが[-1, 1], yが[-l/w, l/w]となるような表現である, ここでl_scaled = l/wである.
// scaleはscreen_sccale * wを指す(pixel単位でのアルファ値の調整に必要)
struct out_vertex_LineDash {
    float4 position_ndc [[ position ]];
    float2 position_scaled;
    float  l_scaled  [[ flat ]];
    float  scale     [[ flat ]];
    float  depth     [[ flat ]];
    float  depth_add [[ flat ]];
};


template <typename OutputType>
inline OutputType LineDashVertexCore(const float2 start_ndc, const float2 end_ndc, const uchar spec, const float line_width, constant uniform_projection& projection)
{
    const float coef_along = (2 * (spec % 2)) -1;
    const float coef_perp = (2 * ((spec % 2 == 0) ^ (spec % 5 == 0))) - 1;
    const float w = 0.5 * line_width;
    const float2 size = 0.5 * projection.physical_size;
    
    const float2 mid_ndc = 0.5 * (start_ndc + end_ndc);
    const float2 dir_view = (mid_ndc - start_ndc) * size;
    const float2 along_view = w * normalize(dir_view);
    const float2 perp_view = float2(along_view.y, -along_view.x);
    const float2 dir_scaled = (dir_view + along_view) / w;
    
    const float l_scaled = length(dir_scaled);
    const float2 pos_ndc = mid_ndc + (((coef_along * (dir_view + along_view)) + (coef_perp * perp_view)) / size);
    
    OutputType output;
    output.position_ndc = float4(pos_ndc, 0, 1);
    output.l_scaled = l_scaled;
    output.scale = projection.screen_scale * w;
    output.position_scaled = float2(coef_perp, coef_along * l_scaled);
    return output;
}

template <typename InputType>
inline float LineDashFragmentCore(thread const InputType input)
{
    float2 position = input.position_scaled;
    const float l = input.l_scaled - 1;
    const float y = position.y;
    position.y = ((y >= l) * (y - l)) + ((y <= -l) * (y + l));
    
    const float distance_from_circle_in_px = (input.scale * (length(position) - 1)) + 0.5;
    return saturate(1.0 - distance_from_circle_in_px);
}

#endif /* LineEngineShader_h */
