//
//  common_private.h
//  MetalChartDev
//
//  Created by Keisuke Mori on 2016/05/13.
//  Copyright © 2016年 freaks. All rights reserved.
//

#ifndef common_private_h
#define common_private_h

// DO NOT INCLUDE THIS FILE IN PUBLIC HEADER FILES!!

#ifdef __OBJC__

#define DEBUG(...) NSLog(__VA_ARGS__)

#else

#define DEBUG(...)

#endif

#endif /* common_private_h */
