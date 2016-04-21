//
//  Points.metal
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/27.
//  Copyright © 2015年 freaks. All rights reserved.
//

#include "../Base/Shader_common.h"

#import "Point_common.h"

template <typename OutType>
inline void PointVertexCore(
							const float2 pos_data,
							constant uniform_point& attrs,
							constant uniform_projection_cart2d& proj,
							thread OutType& out
							)
{
	const float2 pos_ndc = data_to_ndc(pos_data, proj);
	out.position = float4(pos_ndc.x, pos_ndc.y, 0, 1.0);
	out.psize = attrs.rad_outer + 1;
	out.point_size = 2 * out.psize; // rad_inner > rad_outer とかそんなん知らん！無駄ァ!
}

template <typename InType>
inline float4 PointFragmentCore(
								thread const InType& in,
								thread const float2& pos_coord,
								constant uniform_point& attrs,
								constant uniform_projection_cart2d& proj
								)
{
	const float2 pos_view = in.psize * ( (2 * pos_coord) - 1 );
	const float r = length(pos_view);
	const float dist_from_inner = (r - attrs.rad_inner) * proj.screen_scale + 0.5;
	const float dist_from_outer = (r - attrs.rad_outer) * proj.screen_scale + 0.5;
	const float ratio_inner = saturate(1 - dist_from_inner);
	const float ratio_outer = saturate(1 - dist_from_outer);
	
	float4 color = (ratio_inner * attrs.color_inner) + ((1 - ratio_inner) * attrs.color_outer);
	color.a *= ratio_outer;
	return color;
}





struct out_vertex {
	float4 position [[ position ]];
	float  point_size [[ point_size ]];
	float  psize	[[ flat ]];
};

vertex out_vertex Point_VertexOrdered(
									  device vertex_float2 *vertices [[ buffer(0) ]],
									  constant uniform_point& point [[ buffer(2) ]],
									  constant uniform_projection_cart2d& proj [[ buffer(3) ]],
									  constant uniform_series_info& info [[ buffer(4) ]],
									  const uint vid [[ vertex_id ]]
									  )
{
	const float2 pos_data = vertices[vid % info.vertex_capacity].position;
	out_vertex out;
	PointVertexCore(pos_data, point, proj, out);
	return out;
}

vertex out_vertex Point_VertexIndexed(
									  device vertex_float2 *vertices [[ buffer(0) ]],
									  device vertex_index *indices  [[ buffer(1) ]],
									  constant uniform_point& point [[ buffer(2) ]],
									  constant uniform_projection_cart2d& proj [[ buffer(3) ]],
									  constant uniform_series_info& info [[ buffer(4) ]],
									  const uint vid [[ vertex_id ]]
									  )
{
	const uint vcap = info.vertex_capacity;
	const uint icap = info.index_capacity;
	const uint index = (indices[vid % icap].index) % vcap;
	const float2 pos_data = vertices[index].position;
	out_vertex out;
	PointVertexCore(pos_data, point, proj, out);
	
	return out;
}

fragment out_fragment Point_Fragment(
									 const out_vertex in [[ stage_in ]],
									 const float2 pos_coord [[ point_coord ]],
									 constant uniform_point& point [[ buffer(0) ]],
									 constant uniform_projection_cart2d& proj [[ buffer(1) ]]
									 )
{
	out_fragment out;
	out.color = PointFragmentCore(in, pos_coord, point, proj);
	
	return out;
}

