//
//  chart_common.h
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/08/07.
//  Copyright © 2015年 freaks. All rights reserved.
//

#ifndef chart_common_h
#define chart_common_h

#ifdef __cplusplus

#endif

//#define __METALKIT_AVAILABLE__

#ifdef __METALKIT_AVAILABLE__

#import <MetalKit/MetalKit.h>

@compatibility_alias MetalView MTKView;

@protocol MetalViewDelegate<MTKViewDelegate>
@end

#else

#import <Metal/Metal.h>
#import "FMMetalView.h"

@compatibility_alias MetalView FMMetalView;

@protocol MetalViewDelegate<FMMetalViewDelegate>
@end

#endif

#endif /* chart_common_h */
