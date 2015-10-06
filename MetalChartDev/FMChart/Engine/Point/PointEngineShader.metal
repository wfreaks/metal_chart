//
//  Points.metal
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/08/27.
//  Copyright © 2015年 freaks. All rights reserved.
//

#include "../Base/Shader_common.h"


struct out_vertex {
    float4 position [[ position ]];
    float  point_size [[ point_size ]];
    float  psize    [[ flat ]];
};

struct uniform_point {
    float4 color_inner;
    float4 color_outer;
    
    float rad_inner;
    float rad_outer;
};

vertex out_vertex Point_VertexOrdered(
                                      device vertex_coord *vertices [[ buffer(0) ]],
                                      constant uniform_point& point [[ buffer(2) ]],
                                      constant uniform_projection& proj [[ buffer(3) ]],
                                      constant uniform_series_info& info [[ buffer(4) ]],
                                      const uint vid [[ vertex_id ]]
                                      )
{
    const float2 pos_data = vertices[vid % info.vertex_capacity].position;
    const float2 pos_ndc = data_to_ndc(pos_data, proj);
    
    out_vertex out;
    out.position = float4(pos_ndc.x, pos_ndc.y, 0, 1.0);
    out.psize = point.rad_outer + 1;
    out.point_size = 2 * out.psize; // rad_inner > rad_outer とかそんなん知らん！無駄ァ!
    
    return out;
}

vertex out_vertex Point_VertexIndexed(
									  device vertex_coord *vertices [[ buffer(0) ]],
									  device vertex_index *indices  [[ buffer(1) ]],
									  constant uniform_point& point [[ buffer(2) ]],
									  constant uniform_projection& proj [[ buffer(3) ]],
									  constant uniform_series_info& info [[ buffer(4) ]],
									  const uint vid [[ vertex_id ]]
									  )
{
	const uint vcap = info.vertex_capacity;
	const uint icap = info.index_capacity;
	const uint index = (indices[vid % icap].index) % vcap;
	const float2 pos_data = vertices[index].position;
	const float2 pos_ndc = data_to_ndc(pos_data, proj);
	
	out_vertex out;
	out.position = float4(pos_ndc.x, pos_ndc.y, 0, 1.0);
	out.psize = point.rad_outer + 1;
	out.point_size = 2 * out.psize; // rad_inner > rad_outer とかそんなん知らん！無駄ァ!
	
	return out;
}


fragment out_fragment Point_Fragment(
                                     const out_vertex in [[ stage_in ]],
                                     const float2 pos_coord [[ point_coord ]],
                                     constant uniform_point& point [[ buffer(0) ]],
                                     constant uniform_projection& proj [[ buffer(1) ]]
                                     )
{
    const float2 pos_view = in.psize * ( (2 * pos_coord) - 1 );
    const float r = length(pos_view);
    const float dist_from_inner = (r - point.rad_inner) * proj.screen_scale + 0.5;
    const float dist_from_outer = (r - point.rad_outer) * proj.screen_scale + 0.5;
    const float ratio_inner = saturate(1 - dist_from_inner);
    const float ratio_outer = saturate(1 - dist_from_outer);
    
    out_fragment out;
    out.color = (ratio_inner * point.color_inner) + ((1 - ratio_inner) * point.color_outer);
    out.color.a *= ratio_outer;
    
    return out;
}

