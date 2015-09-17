//
//  TextureQuad.metal
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/09/16.
//  Copyright © 2015年 freaks. All rights reserved.
//

#include "Shader_common.h"

struct uniform_region {
    float2 base_pos;
    float2 iter_vec;
    float2 anchor;
    float2 size;
    
    float iter_offset;
};

struct out_vertex {
    float4 position [[ position ]];
    float2 uv;
};

struct out_fragment {
    float4 color [[ color(0) ]];
};

inline float2 spec_to_coef(const uint spec) {
    const float is_right = ((spec%2) == 0);
    const float is_top = (spec%2 == 0) ^ (spec%5 == 0);
    return float2((2*is_right)-1, (2*is_top)-1);
}

inline float2 position_with_region(const uint qid, const uint spec, constant uniform_region& region)
{
    const float2 base = region.base_pos + ((qid + region.iter_offset) * region.iter_vec);
    const float2 diff = 0.5 * region.size;
    const float2 center = base + (diff * (float2(0.5, 0.5) - region.anchor));
    const float2 pos = (spec_to_coef(spec) * diff) + center;
    return pos;
}

vertex out_vertex TextureQuad_vertex(
                                     constant uniform_region& region_view [[ buffer(0) ]],
                                     constant uniform_region& region_uv   [[ buffer(1) ]],
                                     constant uniform_projection& proj    [[ buffer(2) ]],
                                     const uint vid_raw [[ vertex_id ]]
                                     )
{
    const uint qid = vid_raw / 6;
    const uint spec = vid_raw % 6;
    const float2 pos_view = position_with_region(qid, spec, region_view);
    const float2 pos_uv = position_with_region(qid, spec, region_uv);
    
    out_vertex out;
    out.position = float4(view_to_ndc(pos_view, false, proj), 0, 1);
    out.uv = pos_uv;
    
    return out;
}

constexpr sampler st(filter::linear);

fragment out_fragment TextureQuad_fragment(
                                           out_vertex in[[ stage_in ]],
                                           texture2d<float> tex [[ texture(0) ]]
                                           )
{
    out_fragment out;
    out.color = tex.sample(st, in.uv);
    
    return out;
}
