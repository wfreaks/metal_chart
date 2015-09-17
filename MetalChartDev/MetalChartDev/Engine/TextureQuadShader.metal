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
    float2 size;   // size, offsetは他のフィールドと異なり、文脈によって意味合い、座標空間が変わる.
	float2 offset; // uv(texture)ではそのままuv, dataではview空間での値となる.
    
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
    const float2 center = base + (2 * diff * (float2(0.5, 0.5) - region.anchor)) + region.offset;
    const float2 pos = (spec_to_coef(spec) * diff) + center;
    return pos;
}

inline float2 position_with_region_view_sized(const uint qid, const uint spec, constant uniform_region& region, constant uniform_projection& proj)
{
    const float2 base = region.base_pos + ((qid + region.iter_offset) * region.iter_vec);
    const float2 diff_data = view_diff_to_data_diff(0.5 * region.size, false, proj);
	const float2 offset_data = view_diff_to_data_diff(region.size, false, proj);
    const float2 center = base + (2 * diff_data * (float2(0.5, 0.5) - region.anchor)) + offset_data;
    const float2 pos = (spec_to_coef(spec) * diff_data) + center;
    return pos;
}

vertex out_vertex TextureQuad_vertex(
                                     constant uniform_region& region_data [[ buffer(0) ]],
                                     constant uniform_region& region_uv   [[ buffer(1) ]],
                                     constant uniform_projection& proj    [[ buffer(2) ]],
                                     const uint vid_raw [[ vertex_id ]]
                                     )
{
    const uint qid = vid_raw / 6;
    const uint spec = vid_raw % 6;
    const float2 pos_data = position_with_region_view_sized(qid, spec, region_data, proj);
    const float2 pos_uv = position_with_region(qid, spec, region_uv);
    
    out_vertex out;
    out.position = float4(data_to_ndc(pos_data, proj), 0, 1);
    out.uv = pos_uv;
//    out.uv = (0.5 * spec_to_coef(spec)) + 0.5;
    
    return out;
}

// textureへのアクセスはピクセルベース、かつy軸のみリピートとする。リピートにするのはRingBuffer的な使い方を許容するため.
constexpr sampler st = sampler(filter::linear, t_address::repeat, r_address::repeat);

fragment out_fragment TextureQuad_fragment(
                                           out_vertex in[[ stage_in ]],
                                           texture2d<float> tex [[ texture(0) ]]
                                           )
{
    out_fragment out;
    out.color = tex.sample(st, in.uv);
    
    return out;
}
