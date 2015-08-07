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

#include <array>

namespace mtl_chart {

    struct dimension {
    };
    
    template <std::size_t N>
    struct space {
        std::array<std::shared_ptr<dimension>, N> _dims;
    }
    
    struct range {
        std::shared_ptr<dimension> _dim;
        float _min;
        float _max;
    };
    
    template <std::size_t N>
    struct projection {
        std::shared_ptr<space<N>> _space;
        std::array<std::shared_ptr<range>, N> _ranges;
    };
    
    
    
}


#endif


#endif /* chart_common_h */
