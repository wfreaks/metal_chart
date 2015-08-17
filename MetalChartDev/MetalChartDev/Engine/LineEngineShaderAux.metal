//
//  LineEngineShaderAux.metal
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/08/17.
//  Copyright © 2015年 freaks. All rights reserved.
//

#include <metal_stdlib>
#include "LineEngineShader.h"

using namespace metal;

struct uniform_axis {
    float2 axis_mid_pos;
    float2 axis_dir_vec;
    
    float4 color_axis;
    float4 color_tick_major;
    float4 color_tick_minor;
    
    float  width_axis;
    float  width_tick_major;
    float  width_tick_minor;
    
    float  length_axis;
    float  length_tick_major;
    float  length_tick_minor;
    
    float  axis_anchor_value;
    float  tick_anchor_value;
    
    uint   dimIndex;
    uchar  minor_ticks_per_major;
    uchar  max_major_ticks;
    uchar  anchor_fixed;
};

struct out_vertex_axis {
    float4 position [[ position ]];
    float4 color    [[ flat ]];
    float2 mid_pos  [[ flat ]];
    float2 vec_dir  [[ flat ]];
    float2 pos;
    float  coef;
    float  width    [[ flat ]];
};

vertex out_vertex_axis AxisVertex(
                                  constant uniform_axis& axis       [[ buffer(0) ]],
                                  constant uniform_projection& proj [[ buffer(1) ]],
                                  uint v_id [[ vertex_id ]]
                                  )
{
    const uint vid = v_id / 6;
    const uchar spec = v_id % 6;
    const bool is_axis = (vid == 0);
    const bool is_major = (0 < vid && vid <= axis.max_major_ticks);
    const uint tick_index = (is_major) ? (vid-1) : (vid-(axis.max_major_ticks+1));
}
