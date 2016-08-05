//
//  LineEngine.metal
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/03.
//  Copyright © 2015 Keisuke Mori. All rights reserved.
//

#include "LineEngineShader.h"

vertex out_vertex_LineDash PolyLineEngineVertexOrdered(
													   device   vertex_float2*             coords [[ buffer(0) ]],
													   constant uniform_line_conf&           conf [[ buffer(1) ]],
													   constant uniform_line_attr&           attr [[ buffer(2) ]],
													   constant uniform_projection_cart2d&   proj [[ buffer(3) ]],
													   constant uniform_series_info&         info [[ buffer(4) ]],
													   const    uint                         v_id [[ vertex_id ]]
) {
	const uint vid = v_id / 6;
	const uint vcap = info.vertex_capacity;
	const ushort index_current = vid % vcap;
	const ushort index_next = (vid + 1) % vcap;
	const float2 p_current = data_to_ndc( coords[index_current].position, proj );
	const float2 p_next = data_to_ndc( coords[index_next].position, proj );
	
	const uchar spec = v_id % 6;
	out_vertex_LineDash out = LineDashVertexCore<out_vertex_LineDash>(p_current, p_next, spec, attr.width, proj);
	out.depth = conf.depth;
	out.depth_add = (vid-info.offset) * 0.1 / (vcap*2);
	return out;
}

fragment out_fragment_depthGreater LineEngineFragment_NoOverlay(
																const    out_vertex_LineDash        input [[ stage_in ]],
																constant uniform_line_conf&          conf [[ buffer(0) ]],
																constant uniform_line_attr&          attr [[ buffer(1) ]],
																constant uniform_projection_cart2d&  proj [[ buffer(2) ]]
) {
	const float ratio = LineDashFragmentCore(input);
	out_fragment_depthGreater out;
	out.color = attr.color;
	out.color.a *= conf.alpha * round(ratio);
	out.depth = (out.color.a > 0) * input.depth;
	
	return out;
}

fragment out_fragment_depthGreater LineEngineFragment_Overlay(
															  const    out_vertex_LineDash        input [[ stage_in ]],
															  constant uniform_line_conf&          conf [[ buffer(0) ]],
															  constant uniform_line_attr&          attr [[ buffer(1) ]],
															  constant uniform_projection_cart2d&  proj [[ buffer(2) ]]
) {
	const float ratio = LineDashFragmentCore(input);
	out_fragment_depthGreater out;
	out.color = attr.color;
	out.color.a *= conf.alpha * ratio;
	out.depth = (out.color.a > 0) * (input.depth + input.depth_add);
	
	return out;
}

fragment out_fragment_depthGreater DashedLineFragment_NoOverlay(
																const    out_vertex_LineDash        input [[ stage_in ]],
																constant uniform_line_conf&          conf [[ buffer(0) ]],
																constant uniform_line_attr&          attr [[ buffer(1) ]],
																constant uniform_projection_cart2d&  proj [[ buffer(2) ]]
																) {
	const float ratio = LineDashFragmentCore(input);
	const float ratio_b = LineDashFragmentExtra(input, attr);
	out_fragment_depthGreater out;
	out.color = attr.color;
	out.color.a *= conf.alpha * round(min(ratio, ratio_b));
	out.depth = (out.color.a > 0) * input.depth;
	
	return out;
}

fragment out_fragment_depthGreater DashedLineFragment_Overlay(
															  const    out_vertex_LineDash        input [[ stage_in ]],
															  constant uniform_line_conf&          conf [[ buffer(0) ]],
															  constant uniform_line_attr&          attr [[ buffer(1) ]],
															  constant uniform_projection_cart2d&  proj [[ buffer(2) ]]
															  ) {
	const float ratio = LineDashFragmentCore(input);
	const float ratio_b = LineDashFragmentExtra(input, attr);
	out_fragment_depthGreater out;
	out.color = attr.color;
	out.color.a *= conf.alpha * min(ratio, ratio_b);
	out.depth = (out.color.a > 0) * (input.depth + input.depth_add);
	
	return out;
}

vertex out_vertex_LineDashAttributed AttributedPolyLineEngineVertexOrdered(
																		   device   indexed_float2*            coords [[ buffer(0) ]],
																		   constant uniform_line_conf&                 conf [[ buffer(1) ]],
																		   constant uniform_line_attr*          attrs_array [[ buffer(2) ]],
																		   constant uniform_projection_cart2d&         proj [[ buffer(3) ]],
																		   constant uniform_series_info&               info [[ buffer(4) ]],
																		   const    uint                               v_id [[ vertex_id ]]
																		   )
{
	const uint vid = v_id / 6;
	const uint vcap = info.vertex_capacity;
	const ushort index_current = vid % vcap;
	const ushort index_next = (vid + 1) % vcap;
	const indexed_float2 v_current = coords[index_current];
	const indexed_float2 v_next = coords[index_next];
	const uint index_attrs = v_current.idx;
	constant uniform_line_attr& attrs = attrs_array[index_attrs];
	const float2 p_current = data_to_ndc( v_current.value, proj );
	const float2 p_next = data_to_ndc( v_next.value, proj );
	
	const uchar spec = v_id % 6;
	out_vertex_LineDashAttributed out = LineDashVertexCore<out_vertex_LineDashAttributed>(p_current, p_next, spec, attrs.width, proj);
	out.depth = conf.depth;
	out.depth_add = (vid-info.offset) * 0.1 / (vcap*2);
	out.idx = index_attrs;
	return out;
}

fragment out_fragment_depthGreater AttributedLineFragment_NoOverlay(
																	const    out_vertex_LineDashAttributed        input [[ stage_in  ]],
																	constant uniform_line_conf&                    conf [[ buffer(0) ]],
																	constant uniform_line_attr*             attrs_array [[ buffer(1) ]],
																	constant uniform_projection_cart2d&            proj [[ buffer(2) ]]
																	)
{
	constant uniform_line_attr& attr = attrs_array[input.idx];
	const float ratio = LineDashFragmentCore(input);
	const float ratio_b = LineDashFragmentExtra(input, attr);
	out_fragment_depthGreater out;
	out.color = attr.color;
	out.color.a *= conf.alpha * round(min(ratio, ratio_b));
	out.depth = (out.color.a > 0) * input.depth;
	
	return out;
}

fragment out_fragment_depthGreater AttributedLineFragment_Overlay(
																  const    out_vertex_LineDashAttributed        input [[ stage_in  ]],
																  constant uniform_line_conf&                    conf [[ buffer(0) ]],
																  constant uniform_line_attr*             attrs_array [[ buffer(1) ]],
																  constant uniform_projection_cart2d&            proj [[ buffer(2) ]]
																  )
{
	constant uniform_line_attr& attr = attrs_array[input.idx];
	const float ratio = LineDashFragmentCore(input);
	const float ratio_b = LineDashFragmentExtra(input, attr);
	out_fragment_depthGreater out;
	out.color = attr.color;
	out.color.a *= conf.alpha * min(ratio, ratio_b);
	out.depth = (out.color.a > 0) * (input.depth + input.depth_add);
	
	return out;
}

