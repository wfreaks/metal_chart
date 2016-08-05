//
//  common_private.h
//  MetalChartDev
//
//  Created by Keisuke Mori on 2016/05/13.
//  Copyright © 2016 Keisuke Mori. All rights reserved.
//

#ifndef common_private_h
#define common_private_h

// DO NOT INCLUDE THIS FILE IN PUBLIC HEADER FILES!!

#ifdef __OBJC__

#ifdef DEBUG
#define DebugLog(...) NSLog(__VA_ARGS__)
#else
#define DebugLog(...)
#endif

#else

#define DebugLog(...)

#endif

#endif /* common_private_h */
