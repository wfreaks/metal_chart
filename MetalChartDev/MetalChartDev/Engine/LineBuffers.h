//
//  LineBuffers.h
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/08/25.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import "Lines_common.h"

@protocol MTLBuffer;
@class DeviceResource;

@interface UniformLineAttributes : NSObject

@property (readonly, nonatomic) id<MTLBuffer> buffer;
@property (assign, nonatomic) BOOL enableOverlay;

- (id)initWithResource:(DeviceResource *)resource;

- (uniform_line_attr *)attributes;

- (void)setWidth:(CGFloat)width;

- (void)setColorWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;

- (void)setAlpha:(float)alpha;

- (void)setLineLengthModifierStart:(float)start end:(float)end;

- (void)setDepthValue:(float)depth;

@end



@interface UniformAxisAttributes : NSObject

@property (readonly, nonatomic) uniform_axis_attributes *attributes;

- (void)setWidth:(float)width;

- (void)setColorWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;

- (void)setLineLength:(float)length;

- (void)setLengthModifierStart:(float)start end:(float)end;

@end

@interface UniformAxis : NSObject

@property (readonly, nonatomic) id<MTLBuffer> axisBuffer;
@property (readonly, nonatomic) id<MTLBuffer> attributeBuffer;

@property (readonly, nonatomic) UniformAxisAttributes *axisAttributes;
@property (readonly, nonatomic) UniformAxisAttributes *majorTickAttributes;
@property (readonly, nonatomic) UniformAxisAttributes *minorTickAttributes;

@property (assign  , nonatomic) float axisAnchorValue;
@property (assign  , nonatomic) float tickAnchorValue;
@property (assign  , nonatomic) float majorTickInterval;

@property (assign  , nonatomic) uint8_t maxMajorTicks;
@property (assign  , nonatomic) uint8_t minorTicksPerMajor;

- (instancetype)initWithResource:(DeviceResource *)resource;

- (uniform_axis *)axis;

- (void)setDimensionIndex:(uint8_t)index;

@end


