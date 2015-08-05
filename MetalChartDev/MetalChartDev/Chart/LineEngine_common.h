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
	vector_float2 physical_size;
	float scale;
};

struct uniform_line_attr {
	float width;
	vector_float4 color;
};

struct uniform_series_info_buffer {
    uint16_t capacity;
    uint16_t offset;
};

struct vertex_buffer {
	vector_float2 position;
};

struct index_buffer {
	uint32_t index;
};


#endif /* LineEngine_common_h */
