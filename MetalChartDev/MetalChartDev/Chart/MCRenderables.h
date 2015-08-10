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

@interface MCLineSeries : NSObject<MCRenderable>

@property (readonly, nonatomic) Line * _Nonnull line;

- (_Null_unspecified instancetype)initWithLine:(Line * _Nonnull)line;

@end
