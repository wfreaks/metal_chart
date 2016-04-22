//
//  Point_common.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/27.
//  Copyright © 2015年 freaks. All rights reserved.
//

#ifndef Point_common_h
#define Point_common_h

#import <simd/simd.h>

typedef struct {
	vector_float4 color_inner;
	vector_float4 color_outer;
	
	float rad_inner;
	float rad_outer;
} uniform_point_attr;


#endif /* Point_common_h */
