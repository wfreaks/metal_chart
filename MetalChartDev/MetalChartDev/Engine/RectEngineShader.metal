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
};

struct out_fragment {
    float4 color [[ color(0) ]];
};

struct uniform_plot_rect {
    float4 color;
    float  corner_radius;
};

vertex out_vertex PlotRect_Vertex(
                                  constant uniform_plot_rect&  rect [[ buffer(0) ]],
                                  constant uniform_projection& proj [[ buffer(1) ]],
                                  uint v_id [[ vertex_id ]]
                                  )
{
    out_vertex out;
    return out;
}

fragment out_fragment PlotRect_Fragment(
                           constant uniform_plot_rect& rect  [[ buffer(0) ]],
                           constant uniform_projection& proj [[ buffer(1) ]]
                           )
{
    out_fragment out;
    return out;
}
