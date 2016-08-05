//
//  LineEngineShader.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/17.
//  Copyright © 2015 Keisuke Mori. All rights reserved.
//

#ifndef LineEngineShader_h
#define LineEngineShader_h

#include "../Base/Shader_common.h"
#include "Line_common.h"

inline void modify_length(thread float2& start, thread float2& end, float2 modifier, float2 phy_size)
{
	const float2 mid = (start + end) / 2;
	const float2 v = normalize(end-start) / phy_size;
	start = mid + (modifier.x * v);
	end = mid + (modifier.y * v);
}

// 10/07に線のシェーダをオーバホール開始. 段階的に置き換えていく.

// 基本的な考え方は、線の中央を原点、view座標における進行方向単位ベクトルが[0, 1]となるような座標変換をかけた際に、
// position_scaled の xが[-1, 1], yが[-l/w, l/w]となるような表現である, ここでl_scaled = l/wである.
// scaleはscreen_sccale * wを指す(pixel単位でのアルファ値の調整に必要)
struct out_vertex_LineDash {
	float4 position_ndc [[ position ]];
	float2 position_scaled;
	float  l_scaled  [[ flat ]];
	float  scale	 [[ flat ]];
	float  depth	 [[ flat ]];
	float  depth_add [[ flat ]];
};

struct out_vertex_LineDashAttributed {
	float4 position_ndc [[ position ]];
	float2 position_scaled;
	float  l_scaled  [[ flat ]];
	float  scale	 [[ flat ]];
	float  depth	 [[ flat ]];
	float  depth_add [[ flat ]];
	uint   idx       [[ flat ]];
};


template <typename OutputType>
inline OutputType LineDashVertexCore(const float2 start_ndc, const float2 end_ndc, const uchar spec, const float line_width, constant uniform_projection_cart2d& projection)
{
	const float coef_along = (2 * (spec % 2)) -1;
	const float coef_perp = (2 * ((spec % 2 == 0) ^ (spec % 5 == 0))) - 1;
	const float w = 0.5 * line_width;
	const float2 size = 0.5 * projection.physical_size;
	
	const float2 mid_ndc = 0.5 * (start_ndc + end_ndc);
	const float2 dir_view = (mid_ndc - start_ndc) * size;
	const float2 along_view = w * normalize(dir_view);
	const float2 perp_view = float2(along_view.y, -along_view.x);
	const float2 dir_scaled = (dir_view + along_view) / w;
	
	const float l_scaled = length(dir_scaled);
	const float2 pos_ndc = mid_ndc + (((coef_along * (dir_view + along_view)) + (coef_perp * perp_view)) / size);
	
	OutputType output;
	output.position_ndc = float4(pos_ndc, 0, 1);
	output.l_scaled = l_scaled;
	output.scale = projection.screen_scale * w;
	output.position_scaled = float2(coef_perp, coef_along * l_scaled);
	return output;
}

template <typename InputType>
inline float LineDashFragmentCore(thread const InputType input)
{
	float2 position = input.position_scaled;
	const float l = input.l_scaled - 1;
	const float y = position.y;
	position.y = ((y >= l) * (y - l)) + ((y <= -l) * (y + l));
	
	const float distance_from_circle_in_px = (input.scale * (length(position) - 1)) + 1.0;
	return saturate(1.0 - distance_from_circle_in_px);
}

template <typename InputType, typename ParamType>
inline float LineDashFragmentExtra(thread const InputType input, constant ParamType& conf)
{
	const float _lr = conf.length_repeat; // 線長lは使えず、繰り返しパターンのパラメータで決まる.
	const float lr = ((_lr > 0) * _lr) + ((_lr <= 0) * input.l_scaled); // 上記が負または0ならば線の長さを繰り返し単位としてただの線とする.
	const float l = lr + (conf.length_space) + 0.5; // 上記にスペースの分＋端の丸めのためのスペース(片方分)を含め、リピート単位とする.
	const float offset_dash = l * conf.repeat_anchor_dash; // %をとる前に引く値、スケールがリピートサイズになる.
	const float offset_line = input.l_scaled * conf.repeat_anchor_line; // 同上、ただしスケールは線全体.
	float2 pos = input.position_scaled;
	const float y2 = ((pos.y + offset_dash - offset_line) / (2*l)) + 0.5; // リピート長2lで正規化し、真ん中の位置へ持ってくる(floorを使うため).
	const float y3 = (2*l) * ((y2 - floor(y2)) - 0.5); // 正規化された状態で整数部を捨て、リピート状態にし、ずらした分を戻し、スケールを戻す -> [-l, l]となる.
	const float y4 = ((y3 >= lr) * (y3 - lr)) + ((y3 <= -lr) * (y3 + lr));
	pos.y = y4;
	
	const float distance_from_circle_in_px = (input.scale * (length(pos) - 1)) + 1.0;
	return saturate(1.0 - distance_from_circle_in_px);
}

#endif /* LineEngineShader_h */
