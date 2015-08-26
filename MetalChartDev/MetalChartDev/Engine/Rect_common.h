//
//  Rect_common.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/26.
//  Copyright © 2015年 freaks. All rights reserved.
//

#ifndef Rect_common_h
#define Rect_common_h

#include <simd/simd.h>

typedef struct uniform_plot_rect {
    vector_float4 color;
    vector_float4 corner_radius;
} uniform_plot_rect;


#endif /* Rect_common_h */
