//
//  FMRenderablesAux.h
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/11/18.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MetalChart.h"

/*
 * 通常のRenderableと違って、ほとんどGPU側で仕事をするプリミティブだけでは対応できないような、
 * 面倒なものをこちらに突っ込む. C++を使う事を余儀なくされるものもこちら.
 *
 */


@class FMEngine;
@class FMProjectionPolar;
@class FMIndexedFloatBuffer;
@class FMContinuosArcPrimitive;
@class FMUniformSeriesInfo;
@class FMUniformArcAttributesArray;
@class FMUniformArcConfiguration;

@interface FMPieDoughtSeries : NSObject <FMRenderable>

@property (nonatomic, readonly) FMContinuosArcPrimitive * _Nonnull arc;
@property (nonatomic, readonly) FMUniformArcConfiguration * _Nonnull conf;
@property (nonatomic, readonly) FMUniformArcAttributesArray * _Nonnull attrs;
@property (nonatomic, readonly) FMIndexedFloatBuffer * _Nonnull values;
@property (nonatomic)			FMProjectionPolar * _Nullable projection;
@property (nonatomic)			NSUInteger offset;
@property (nonatomic)			NSUInteger count;
@property (nonatomic, readonly) NSUInteger capacity;

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
									arc:(FMContinuosArcPrimitive * _Nonnull)arc
							 projection:(FMProjectionPolar * _Nullable)projection
								 values:(FMIndexedFloatBuffer * _Nullable)values
					   capacityOnCreate:(NSUInteger)capacity
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init
UNAVAILABLE_ATTRIBUTE;

@end

