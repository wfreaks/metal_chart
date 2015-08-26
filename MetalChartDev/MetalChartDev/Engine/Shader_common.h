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

// 命名をミスった感があるが、やる事は data空間上の座標 -> NDC上の座標
inline float2 adjustPoint(float2 value, constant uniform_projection& proj)
{
	const float2 ps = proj.physical_size;
	const float4 pd = proj.rect_padding; // {l, t, r, b} = {x, y, z, w}
	const float2 fixed_vs = proj.value_scale * ps / (ps - float2(pd.x+pd.z, pd.y+pd.w));
	const float2 fixed_or = proj.origin + (float2((pd.x-pd.z), (pd.w-pd.y)) / ps); // ここでwindowのT->Bのy軸からB->TのNDCのy軸になっている事に注意. またfloat2各成分(l-rなど)が1/2されてないのは1/psが吸収しているため.
	return ((value + proj.value_offset) / fixed_vs) + fixed_or;
}

#endif /* Shader_common_h */
