//
//  MCRenderables.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/11.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MetalChart.h"

@class Line;
@class Bar;

@interface MCLineSeries : NSObject<MCRenderable, MCDepthClient>

@property (readonly, nonatomic) Line * _Nonnull line;

- (instancetype _Null_unspecified)initWithLine:(Line * _Nonnull)line;

@end


@interface MCBarSeries : NSObject<MCRenderable>

@property (readonly, nonatomic) Bar * _Nonnull bar;

- (instancetype _Null_unspecified)initWithBar:(Bar * _Nonnull)bar;

@end


@class PlotRect;

@interface MCPlotArea : NSObject<MCAttachment>

@property (readonly, nonatomic) UniformProjection * _Nonnull projection;
@property (readonly, nonatomic) PlotRect * _Nonnull rect;

- (instancetype _Null_unspecified)initWithRect:(PlotRect * _Nonnull)rect;

@end
