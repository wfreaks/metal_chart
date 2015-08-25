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

#endif /* Shader_common_h */
