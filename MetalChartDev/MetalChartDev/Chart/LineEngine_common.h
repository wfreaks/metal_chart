//
//  LineEngine_common.h
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/08/03.
//  Copyright © 2015年 freaks. All rights reserved.
//

#ifndef LineEngine_common_h
#define LineEngine_common_h

#include <simd/simd.h>

struct uniform_projection {
	vector_float2 view_size;
	vector_float2 range_lb;
	vector_float2 range_rt;
};

struct uniform_line_attr {
	float width;
	vector_float4 color;
};

struct vertex_buffer {
	vector_float2 position;
};

struct index_buffer {
	uint32_t index;
};

#endif /* LineEngine_common_h */
