//
//  UIColor+Utility.m
//  FMChart
//
//  Created by Keisuke Mori on 2015/11/03.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "UIColor+Utility.h"

@implementation UIColor (Utility)

- (vector_float4)vector
{
    CGFloat r, g, b, a;
    [self getRed:&r green:&g blue:&b alpha:&a];
    return vector4((float)r, (float)g, (float)b, (float)a);
}

+ (instancetype)colorWithVector:(vector_float4)vector
{
    return [UIColor colorWithRed:vector[0]
                           green:vector[1]
                            blue:vector[2]
                           alpha:vector[3]];
}

@end
