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

struct out_vertex {
    float4 position [[ position ]];
    float2 mid_pos [[ flat ]];
    float2 vec_dir [[ flat ]];
    float2 pos;
    float  coef;
    float  depth [[ flat ]];
    float  depth_add [[ flat ]];
};

struct uniform_line_attr {
    float4 color;
    float2 length_mod;
    float width;
    float depth;
    float alpha;
    uchar modify_alpha_on_edge;
};

// ここの座業変換はlineWidthの値に応じて頂点を「物理座標」上でw/√2だけ動かす。scissorRectはNDCへ影響を与えない(物理座標とNDCの対応関係が変わらない)ので考慮する必要はない.
template <typename OutputType>
inline OutputType LineEngineVertexCore(const float2 current, const float2 next, const uchar spec, const float line_width, const float2 phy_size)
{
    const char along = (2 * (spec % 2)) - 1; // 偶数で-1, 奇数で1にする.
    const char perp = (2 * min(1, spec % 5)) - 1; // 0か5の時に-1, 1~4の時は1にする.
    const float2 vec_diff = (next - current) / 2;
    const float2 size = phy_size / 2;
    const float w = line_width / 2;
    const float2 diff_along_physical = along * w * normalize(vec_diff*size) ;
    const float2 diff_perp_physical = float2( - perp * diff_along_physical.y, perp * diff_along_physical.x );
    const float2 diff_along = diff_along_physical / size;
    const float2 diff_perp = diff_perp_physical / size;
    const float2 pos = (along == 1) ? next : current;
    
    OutputType out;
    out.pos = pos + (diff_along + diff_perp);
    out.position.xy = out.pos;
    out.position.z = 0.5;
    out.position.w = 1;
    out.mid_pos = (current + next) / 2;
    out.vec_dir = vec_diff;
    out.coef = (float)along;
    
    return out;
}

inline void modify_length(thread float2& start, thread float2& end, float2 modifier, float2 phy_size)
{
    const float2 mid = (start + end) / 2;
    const float2 v = normalize(end-start) / phy_size;
    start = mid + (modifier.x * v);
    end = mid + (modifier.y * v);
}

struct out_frag_core {
    bool is_same_dir;
    float ratio;
};

template <typename InputType>
inline out_frag_core LineEngineFragmentCore_ratio(thread const InputType& input, constant uniform_projection& proj, const float width)
{
    const float2 pos = input.pos;
    const float2 size = proj.physical_size / 2;
    const float2 base = input.mid_pos + ( sign(input.coef) * input.vec_dir );
    const float2 dir = (base - input.mid_pos) * size;
    const float w = width / 2;
    const float2 diff = (pos - base) * size;
    const float distance_from_circle_in_px = ((length(diff) - w) * proj.screen_scale) + 0.5;
    out_frag_core out;
    out.is_same_dir = (dot(diff, dir) > 0);
    out.ratio = saturate( 1.0 - distance_from_circle_in_px );
    return out;
}

#endif /* LineEngineShader_h */
