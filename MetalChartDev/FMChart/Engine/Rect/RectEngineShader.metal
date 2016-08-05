//
//  RectEngineShader.metal
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/26.
//  Copyright © 2015 Keisuke Mori. All rights reserved.
//

#include "../Base/Shader_common.h"
#include "Rect_common.h"

struct out_vertex_plot {
	float4 position [[ position ]];
	float2 pos;
	float2 coef;
};

struct out_vertex_bar {
	float4 position [[ position ]];
	float2 pos;
	float2 coef;
	
	float2 dir [[ flat ]];
	float2 center [[ flat ]];
	float  w   [[ flat ]];
	float  l   [[ flat ]];
};

struct out_vertex_bar_attributed {
	float4 position [[ position ]];
	float2 pos;
	float2 coef;
	
	float2 dir [[ flat ]];
	float2 center [[ flat ]];
	float  w   [[ flat ]];
	float  l   [[ flat ]];
	uint   idx [[ flat ]];
};

vertex out_vertex_plot PlotRect_Vertex(
									   constant uniform_plot_rect&  rect [[ buffer(0) ]],
									   constant uniform_projection_cart2d& proj [[ buffer(1) ]],
									   uint v_id [[ vertex_id ]]
									   )
{
	const uint spec = v_id % 4;
	const bool is_right = ((spec % 2) == 1);
	const bool is_top = ((spec / 2) == 0);
	const float2 value = float2( (2*(is_right))-1, (2*(is_top))-1 ); // (±1, ±1)へマッピング.
	const float2 pos = data_to_ndc(value, proj);
	out_vertex_plot out;
	out.position = float4(pos.x, pos.y, 0, 1.0);
	out.pos = pos * (proj.physical_size / 2);
	out.coef = value;
	return out;
}

// pos represents position in view coordinate(dpi scale), regardless of origin/offset(only scale matter).
// rect(x, y, z, w) represents (xMin, xMax, yMin, yMax) of rectangle, must share coordinate system with pos.
inline float RoundRectFragment_core(const float2 pos, const float4 rect, const float r, const float screen_scale)
{
	const float cap_y = min(abs(rect.w - rect.z) * 0.5, r);
	const float cap_diff = r - cap_y;
	const float xMin = rect.x + r;
	const float xMax = rect.y - r;
	const float yMin = rect.z + cap_y;
	const float yMax = rect.w - cap_y;
	
	const float left   = pos.x - xMin;
	const float right  = pos.x - xMax;
	const float bottom = pos.y - yMin;
	const float top	= pos.y - yMax;
	
	const float x = ((left   < 0) * left  ) + ((right > 0) * right);
	const float y = ((bottom < 0) * (bottom-cap_diff)) + ((top   > 0) * (top+cap_diff));
	
	const float2 mapped_pos = float2(x, y);
	const float dist_from_circle_in_px = ( (length(mapped_pos) - r) * screen_scale ) + 0.5;
	const float ratio = saturate(saturate(1 - dist_from_circle_in_px) + (r <= 0)); // r<=0の時には常にalpha値に変更なしにする.
	
	return ratio;
}

fragment out_fragment_depthLess PlotRect_Fragment(
										const out_vertex_plot in [[ stage_in ]],
										constant uniform_plot_rect& rect  [[ buffer(0) ]],
										constant uniform_projection_cart2d& proj [[ buffer(1) ]]
										)
{
	const float2 size = proj.physical_size / 2;
	const float4 padding = proj.rect_padding;
	const float2 signs = sign(in.coef);
	const uchar idx_corner = (signs.x > 0) + (2 * (signs.y <= 0));
	const float r = rect.corner_radius[idx_corner];
	
	const float4 rectangle = float4(padding.x - size.x, size.x - padding.z, padding.w - size.y, size.y - padding.y);
	const float ratio = RoundRectFragment_core(in.pos, rectangle, r, proj.screen_scale);
	
	out_fragment_depthLess out;
	out.color = rect.color;
	out.color.a *= ratio;
	out.depth = ((ratio > 0) * rect.depth_value) + ((ratio <= 0) * 10);
	
	return out;
}

template <typename OutType>
inline void BarVertexCore(const uint v_id,
						  const float2 pos_data,
						  constant uniform_bar_conf& conf,
						  constant uniform_bar_attr& attr,
						  constant uniform_projection_cart2d& proj,
						  thread OutType& out
						  )
{
	const uchar spec = v_id % 6;
	const bool is_right = ((spec % 2) == 1); // spec = [0,2] -> true
	const bool is_top = (spec%2 == 0) ^ (spec%5 == 0); // spec = [0,1] -> true
	// dirが(0,0)の場合は考えない. そんなやつの事は知らん. ちなみに面倒な事に、dirはview空間、anchorはデータ空間となる（rangeによって方向変わるとか許されない）
	const float2 size = proj.physical_size / 2;
	const float  w = attr.width / 2;
	const float2 dir_view = normalize(conf.dir);
	const float2 perp_view(dir_view.y, -dir_view.x);
	const float2 anchor_view = data_to_ndc(conf.anchor_point, proj) * size; // data -> ndc -> view
	const float2 position_view = data_to_ndc(pos_data, proj) * size;
	const float2 root_view = (dot(position_view-anchor_view, perp_view) * perp_view) + anchor_view;
	
	const float2 mid_view = (position_view + root_view) / 2;
	const float2 vec_along_view = position_view - mid_view;
	const float2 vec_perp_view = w * perp_view;
	const float2 coef = float2( (2.0*(is_right))-1, (2.0*(is_top))-1 );
	// dir_viewが上を向く状態で上だの右だのを考える.
	const float2 fixed_pos_view = mid_view + (coef.x * vec_perp_view) + (coef.y * vec_along_view);
	const float2 fixed_pos_ndc = fixed_pos_view / size;
	
	out.position = float4(fixed_pos_ndc.x, fixed_pos_ndc.y, 0, 1.0);
	out.pos = fixed_pos_view;
	out.dir = dir_view;
	out.w   = w;
	out.l   = length(vec_along_view);
	out.coef = coef;
	out.center = mid_view;
}

template <typename InType>
inline float4 BarFragmentCore(thread const InType& in,
							 thread float& ratio,
							 constant uniform_bar_conf& conf,
							 constant uniform_bar_attr& attr,
							 constant uniform_projection_cart2d& proj
							 )
{
	// 手順をまとめてみる. pos及びcenterはデバイス上の位置となっている. dirも同じ座標に従い、かつnormalizeされているものとする.
	// その場合直行するベクトルを求めてその２つで分解する、つまり p = a*dir + b*perp; となるa, bを求める. これは簡単で a = dot(p, dir), b = dot(p, perp)である.
	// ただしこの p は p = pos - center; である.
	// この様に分解したのち、9patchでマッピングする必要があるが、これには形状に関する情報が必要となる. これは in.w , in.l が担当するが、以下の仮定を置いている.
	// lはdir方向の長さ成分、wは垂直方向の成分、どちらもcenterから矩形の境界までの距離に相当する、つまり長さ/2, 太さ/2である.
	// また、dirを上に向ける形で処理を進める. この仮定はcorner_radiusがどう適用されるかに影響される事に注意.
	// ただし現状では、dirと逆方向に棒が伸びる(負値の場合)、t/bは頂点/根元に相当するため入れ替わるが、l/rは棒の進行方向に関係なく維持されることに注意.
	const float4 radius = attr.corner_radius;
	const float2 r_y = (radius.xz + radius.yw) * 0.5;
	const float  y_offset = 0.5 * (r_y.x - r_y.y);
	const float2 p = in.pos - in.center;
	const float2 perp(+in.dir.y, -in.dir.x);
	const float2 pos(dot(p, perp), dot(p, in.dir) + y_offset);
	const float4 rectangle(-in.w, +in.w, -in.l, +in.l);
	const float2 signs = sign(pos);//sign(in.coef);
	// ここの象限を決める際に、radiusに応じたoffsetを取る。横にずれると話がややこしくなるので、まずは縦のみ. 左右があって面倒なので、(l+r)*0.5を基準にしよう.
	const uchar idx_corner = (signs.x > 0) + (2 * (signs.y <= 0));
	const float r = radius[idx_corner];
	ratio = RoundRectFragment_core(pos, rectangle, r, proj.screen_scale);
	
	float4 color = attr.color;
	color.a *= ratio;
	
	return color;
}

vertex out_vertex_bar GeneralBar_VertexOrdered(
											   device vertex_float2 *vertices   [[ buffer(0) ]],
											   constant uniform_bar_conf& conf [[ buffer(1) ]],
											   constant uniform_bar_attr& attr [[ buffer(2) ]],
											   constant uniform_projection_cart2d& proj [[ buffer(3) ]],
											   constant uniform_series_info& info [[ buffer(4) ]],
											   uint v_id [[ vertex_id ]]
											   )
{
	const uint vid = (v_id / 6) % info.vertex_capacity;
	out_vertex_bar out;
	BarVertexCore(v_id, vertices[vid].position, conf, attr, proj, out);
	
	return out;
}

fragment out_fragment_depthGreater GeneralBar_Fragment(
													   const out_vertex_bar in [[ stage_in ]],
													   constant uniform_bar_conf& conf [[ buffer(0) ]],
													   constant uniform_bar_attr& attr [[ buffer(1) ]],
													   constant uniform_projection_cart2d& proj [[ buffer(2) ]]
													   )
{
	float ratio = 0;
	out_fragment_depthGreater out;
	out.color = BarFragmentCore(in, ratio, conf, attr, proj);;
	out.depth = ((ratio > 0) * conf.depth_value);
	
	return out;
}


vertex out_vertex_bar_attributed AttributedBar_VertexOrdered(
															 device indexed_float2 *vertices [[ buffer(0) ]],
															 constant uniform_bar_conf& conf [[ buffer(1) ]],
															 constant uniform_bar_attr* attrs_array [[ buffer(2) ]],
															 constant uniform_projection_cart2d& proj [[ buffer(3) ]],
															 constant uniform_series_info& info [[ buffer(4) ]],
															 uint v_id [[ vertex_id ]]
															 )
{
	const uint vid = (v_id / 6) % info.vertex_capacity;
	const indexed_float2 v = vertices[vid];
	constant uniform_bar_attr& attrs = attrs_array[v.idx];
	out_vertex_bar_attributed out;
	out.idx = v.idx;
	BarVertexCore(v_id, v.value, conf, attrs, proj, out);
	
	return out;
}


fragment out_fragment_depthGreater AttributedBar_Fragment(
														  const out_vertex_bar_attributed in [[ stage_in ]],
														  constant uniform_bar_conf& conf [[ buffer(0) ]],
														  constant uniform_bar_attr* attrs_array [[ buffer(1) ]],
														  constant uniform_projection_cart2d& proj [[ buffer(2) ]]
														  )
{
	constant uniform_bar_attr& attrs = attrs_array[in.idx];
	float ratio = 0;
	out_fragment_depthGreater out;
	out.color = BarFragmentCore(in, ratio, conf, attrs, proj);;
	out.depth = ((ratio > 0) * conf.depth_value);
	
	return out;
}



