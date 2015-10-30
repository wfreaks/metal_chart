//
//  ChartCommon.swift
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/10/30.
//  Copyright © 2015年 freaks. All rights reserved.
//

import Foundation

#if __METALKIT_AVAILABLE__
    import MetalKit
    public typealias MetalView = MTKView;
#else
    public typealias MetalView = FMMetalView;
#endif

