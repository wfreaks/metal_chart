//
//  Shader_common.h
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/08/26.
//  Copyright © 2015年 freaks. All rights reserved.
//

#ifndef Shader_common_h
#define Shader_common_h

#include <metal_stdlib>

using namespace metal;

struct vertex_coord {
    float2 position;
};

struct vertex_index {
    uint index;
};

struct uniform_projection {
    float2 origin;
    float2 value_scale;
    float2 value_offset;
    
    float2 physical_size;
    float4 rect_padding;
    float  screen_scale;
};

struct uniform_series_info {
    uint vertex_capacity;
    uint index_capacity;
    uint offset;
};


inline float2 data_to_ndc(float2 value, constant uniform_projection& proj)
{
	const float2 ps = proj.physical_size;
	const float4 pd = proj.rect_padding; // {l, t, r, b} = {x, y, z, w}
	const float2 fixed_vs = proj.value_scale * ps / (ps - float2(pd.x+pd.z, pd.y+pd.w));
	const float2 fixed_or = proj.origin + (float2((pd.x-pd.z), (pd.w-pd.y)) / ps); // ここでwindowのT->Bのy軸からB->TのNDCのy軸になっている事に注意. またfloat2各成分(l-rなど)が1/2されてないのは1/psが吸収しているため.
	return ((value + proj.value_offset) / fixed_vs) + fixed_or;
}

inline float2 view_to_ndc(const float2 pos_view, const bool bottom_to_top, constant uniform_projection& proj) {
    const float2 psize = proj.physical_size;
    const float y_coef = (2 * bottom_to_top) - 1;
    const float fixed_y_view = ((!bottom_to_top) * proj.physical_size.y) + (y_coef * pos_view.y);
    const float2 fixed_pos_view = float2(pos_view.x, fixed_y_view);
    return (fixed_pos_view - (0.5 * psize)) / psize;
}

inline float2 view_diff_to_data_diff(float2 diff_view, const bool bottom_to_top, constant uniform_projection& proj)
{
    const float2 ps = proj.physical_size;
    const float4 pd = proj.rect_padding; // {l, t, r, b} = {x, y, z, w}
    const float coef_y = ((2 * bottom_to_top) - 1);
    const float2 fixed_diff_view = float2(diff_view.x, coef_y * diff_view.y);
    const float2 fixed_vs = proj.value_scale * ps / (ps - float2(pd.x+pd.z, pd.y+pd.w));
    return (fixed_diff_view / ps) * fixed_vs;
}

#endif /* Shader_common_h */
