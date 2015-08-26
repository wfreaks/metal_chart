//
//  Rects.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/26.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Engine;
@class UniformProjection;
@class UniformPlotRect;;

@protocol MTLRenderCommandEncoder;

@interface PlotRect : NSObject

@property (readonly, nonatomic) Engine * _Nonnull engine;
@property (readonly, nonatomic) UniformPlotRect * _Nonnull rect;

- (instancetype _Null_unspecified)initWithEngine:(Engine * _Nonnull)engine;

- (void)encodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
        projection:(UniformProjection * _Nonnull)projection
;

@end
