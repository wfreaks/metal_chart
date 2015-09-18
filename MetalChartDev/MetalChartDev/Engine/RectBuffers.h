//
//  RectBuffers.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/26.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import "Rect_common.h"

@protocol MTLBuffer;
@class DeviceResource;

@interface UniformPlotRect : NSObject

@property (readonly, nonatomic) id<MTLBuffer> _Nonnull buffer;
@property (readonly, nonatomic) uniform_plot_rect * _Nonnull rect;

- (instancetype _Nonnull)initWithResource:(DeviceResource * _Nonnull)resource;

- (void)setColor:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;
- (void)setCornerRadius:(float)lt rt:(float)rt lb:(float)lb rb:(float)rb;
- (void)setCornerRadius:(float)radius;

@end


@interface UniformBar : NSObject

@property (readonly, nonatomic) id<MTLBuffer> _Nonnull buffer;
@property (readonly, nonatomic) uniform_bar * _Nonnull bar;

- (instancetype _Nonnull)initWithResource:(DeviceResource * _Nonnull)resource;

- (void)setColor:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;
- (void)setCornerRadius:(float)lt rt:(float)rt lb:(float)lb rb:(float)rb;
- (void)setCornerRadius:(float)radius;
- (void)setBarWidth:(float)width;
- (void)setAnchorPoint:(CGPoint)point;
- (void)setBarDirection:(CGPoint)dir;

@end
