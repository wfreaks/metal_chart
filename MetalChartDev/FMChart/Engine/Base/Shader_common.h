//
//  Shader_common.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/26.
//  Copyright © 2015年 freaks. All rights reserved.
//

#ifndef Shader_common_h
#define Shader_common_h

#include <metal_stdlib>

#include "base_shared.h"

using namespace metal;

struct out_fragment {
	float4 color [[ color(0) ]];
};

struct out_fragment_depthGreater {
	float4 color [[ color(0) ]];
	float  depth [[ depth(greater) ]];
};

struct out_fragment_depthLess {
	float4 color [[ color(0) ]];
	float  depth [[ depth(less) ]];
};

struct out_fragment_depthAny {
	float4 color [[ color(0) ]];
	float  depth [[ depth(any) ]];
};

inline float2 data_to_ndc(const float2 value, constant uniform_projection_cart2d& proj)
{
	const float2 ps = proj.physical_size;
	const float4 pd = proj.rect_padding; // {l, t, r, b} = {x, y, z, w}
	const float2 fixed_vs = proj.value_scale * ps / (ps - float2(pd.x+pd.z, pd.y+pd.w));
	const float2 fixed_or = proj.origin + (float2((pd.x-pd.z), (pd.w-pd.y)) / ps); // ここでwindowのT->Bのy軸からB->TのNDCのy軸になっている事に注意. またfloat2各成分(l-rなど)が1/2されてないのは1/psが吸収しているため.
	return ((value + proj.value_offset) / fixed_vs) + fixed_or;
}

// これはパディングとかを無視した[-1, 1] -> [vmin, vmax]変換用. 上のdata_to_ndcのそれとは違う.
inline float2 semi_ndc_to_data(const float2 ndc, constant uniform_projection_cart2d& proj)
{
	return (ndc * proj.value_scale) - proj.value_offset;
}

// valueは[r,theta]の順を仮定している
inline float2 polar_to_ndc(const float2 value, constant uniform_projection_polar& proj)
{
	const float2 _ps = 2 / proj.physical_size;
	const float4 pd = proj.rect_padding;
	const float2 diff_pad = 0.5 * float2(pd.x - pd.z, pd.y - pd.w);
	const float2 diff = proj.radius_scale * value.x * float2(cos(value.y), sin(value.y));
	return proj.origin_ndc + ((proj.origin_offset + diff + diff_pad) * _ps);
}

template <typename ProjectionType>
inline float2 view_to_ndc(const float2 pos_view, const bool bottom_to_top, constant ProjectionType& proj) {
	const float2 psize = proj.physical_size;
	const float y_coef = (2 * bottom_to_top) - 1;
	const float fixed_y_view = ((!bottom_to_top) * proj.physical_size.y) + (y_coef * pos_view.y);
	const float2 fixed_pos_view = float2(pos_view.x, fixed_y_view);
	return (fixed_pos_view - (0.5 * psize)) / psize;
}

template <typename ProjectionType>
inline float2 view_diff_to_data_diff(float2 diff_view, const bool bottom_to_top, constant ProjectionType& proj)
{
	const float2 ps = proj.physical_size;
	const float4 pd = proj.rect_padding; // {l, t, r, b} = {x, y, z, w}
	const float coef_y = ((2 * bottom_to_top) - 1);
	const float2 fixed_diff_view = float2(diff_view.x, coef_y * diff_view.y);
	const float2 fixed_vs = proj.value_scale * ps / (ps - float2(pd.x+pd.z, pd.y+pd.w));
	return 2 * (fixed_diff_view / ps) * fixed_vs;
}

#endif /* Shader_common_h */
