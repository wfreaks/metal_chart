//
//  LineBuffers.h
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/08/25.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import "Line_common.h"

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

- (instancetype)initWithAttributes:(uniform_axis_attributes *)attr;

- (void)setWidth:(float)width;

- (void)setColorWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;

- (void)setLineLength:(float)length;

- (void)setLengthModifierStart:(float)start end:(float)end;

@end

// 他のUniform系と異なりほとんどがreadableなプロパティで定義されているのは、
// Attributeと違い設定はCPU側で参照される事が多いためである。
// CPU/GPU共有バッファは出来れば書き込み専用にしたいので、プロパティへのミラリングをしている.

@interface UniformAxisConfiguration : NSObject

@property (readonly, nonatomic) id<MTLBuffer> axisBuffer;

@property (assign  , nonatomic) float axisAnchorValue;
@property (assign  , nonatomic) float tickAnchorValue;
@property (assign  , nonatomic) float majorTickInterval;
@property (assign  , nonatomic) uint8_t minorTicksPerMajor;

// basically there is no need of setting properties below.
// maxMajorTicks gets overridden at every frame, and dimensionIndex will be set by classes in upper layer.
// if you want to set dimensionIndex manually, then you should read shader codes and MCAxisLabel
// implementation before doing so.

@property (assign  , nonatomic) uint8_t dimensionIndex;
@property (assign  , nonatomic) uint8_t maxMajorTicks;

// MCAxisLabel use this property and 'checkIfMajorTickValueModified:' method to avoid redundant
// buffer updates.
@property (readonly, nonatomic) BOOL majorTickValueModified;

- (instancetype)initWithResource:(DeviceResource *)resource;

- (uniform_axis_configuration *)axis;

// if majorTickValueModified is YES, then ifModified will be invoked, and clear the flag when YES is returned from it.
// return value of this method is identical to majorTickValueModified.
- (BOOL)checkIfMajorTickValueModified:(BOOL (^)(UniformAxisConfiguration *))ifModified;

@end


