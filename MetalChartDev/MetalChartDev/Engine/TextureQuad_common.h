//
//  TextureQuad_common.h
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/09/16.
//  Copyright © 2015年 freaks. All rights reserved.
//

#ifndef TextureQuad_common_h
#define TextureQuad_common_h

#import <simd/simd.h>

typedef struct uniform_region {
    vector_float2 base_pos;
    vector_float2 iter_vec;
    vector_float2 anchor;
    vector_float2 size;
    
    float iter_offset;
} uniform_region;

#endif /* TextureQuad_common_h */
