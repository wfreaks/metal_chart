//
//  SharedStructures.h
//  minimal_chart
//
//  Created by Keisuke Mori on 2015/08/04.
//  Copyright (c) 2015年 foolog. All rights reserved.
//

#ifndef SharedStructures_h
#define SharedStructures_h

#include <simd/simd.h>

typedef struct
{
    matrix_float4x4 modelview_projection_matrix;
    matrix_float4x4 normal_matrix;
} uniforms_t;

#endif /* SharedStructures_h */

