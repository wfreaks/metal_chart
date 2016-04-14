//
//  UIColor+Utility.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/11/03.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <simd/simd.h>

@interface UIColor (Utility)

- (vector_float4)vector;

+ (instancetype)colorWithVector:(vector_float4)vector;

@end
