//
//  MCRenderables.m
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/11.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "MCRenderables.h"
#import "DeviceResource.h"
#import "Lines.h"
#import "Rects.h"

@implementation MCLineSeries

- (instancetype)initWithLine:(Line *)line
{
	self = [super init];
	if(self) {
		_line = line;
	}
	return self;
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
		projection:(UniformProjection *)projection
{
	[_line encodeWith:encoder projection:projection];
}

- (CGFloat)requestDepthRangeFrom:(CGFloat)min
{
    [_line.attributes setDepthValue:min];
    return 0.1;
}

@end



@implementation MCBarSeries

- (instancetype)initWithBar:(Bar *)bar
{
    self = [super init];
    if(self) {
        _bar = bar;
    }
    return self;
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder projection:(UniformProjection *)projection
{
    [_bar encodeWith:encoder projection:projection];
}

@end



@implementation MCPlotArea

- (instancetype)initWithRect:(PlotRect *)rect
{
    self = [super init];
    if(self) {
        DeviceResource *res = rect.engine.resource;
        _projection = [[UniformProjection alloc] initWithResource:res];
        _projection.enableScissor = NO;
        _rect = rect;
    }
    return self;
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
             chart:(MetalChart *)chart
              view:(MTKView *)view
{
    [_projection setPhysicalSize:view.bounds.size];
    [_projection setSampleCount:view.sampleCount];
    [_projection setColorPixelFormat:view.colorPixelFormat];
    [_projection setPadding:chart.padding];
    
    [_rect encodeWith:encoder projection:_projection];
}

@end
