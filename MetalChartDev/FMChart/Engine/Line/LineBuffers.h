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
@class FMDeviceResource;

@interface FMUniformLineAttributes : NSObject

@property (readonly, nonatomic) id<MTLBuffer> _Nonnull buffer;
@property (readonly, nonatomic) uniform_line_attr * _Nonnull attributes;

@property (assign, nonatomic) BOOL enableOverlay;

// 破線処理を考慮したシェーダは考慮しないものと比較するとGPU負荷が1.5倍程度になるので、
// 明示的に切り替え用のフラグを用意する.
@property (assign, nonatomic) BOOL enableDash;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource;

- (void)setWidth:(CGFloat)width;

- (void)setColorWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;
- (void)setColor:(vector_float4 const * _Nonnull)color;

- (void)setAlpha:(float)alpha;

- (void)setLineLengthModifierStart:(float)start end:(float)end;

- (void)setDepthValue:(float)depth;

- (void)setDashLineLength:(float)length;

- (void)setDashSpaceLength:(float)length;

- (void)setDashLineAnchor:(float)anchor;

- (void)setDashRepeatAnchor:(float)anchor;

@end



@interface FMUniformAxisAttributes : NSObject

@property (readonly, nonatomic) uniform_axis_attributes * _Nonnull attributes;

- (instancetype _Nonnull)initWithAttributes:(uniform_axis_attributes * _Nonnull)attr;

- (void)setWidth:(float)width;

- (void)setColorRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;
- (void)setColor:(vector_float4)color;
- (void)setColorRef:(vector_float4 const * _Nonnull)color;

- (void)setLineLength:(float)length;

- (void)setLengthModifierStart:(float)start end:(float)end;

@end

// 他のUniform系と異なりほとんどがreadableなプロパティで定義されているのは、
// Attributeと違い設定はCPU側で参照される事が多いためである。
// CPU/GPU共有バッファは出来れば書き込み専用にしたいので、プロパティへのミラリングをしている.

@interface FMUniformAxisConfiguration : NSObject

@property (readonly, nonatomic) id<MTLBuffer> _Nonnull buffer;
@property (readonly, nonatomic) uniform_axis_configuration * _Nonnull configuration;

@property (assign  , nonatomic) float axisAnchorValue;
@property (assign  , nonatomic) float tickAnchorValue;
@property (assign  , nonatomic) float majorTickInterval;
@property (assign  , nonatomic) uint8_t minorTicksPerMajor;

// basically there is no need of setting properties below.
// maxMajorTicks gets overridden at every frame, and dimensionIndex will be set by classes in upper layer.
// if you want to set dimensionIndex manually, then you should read shader codes and FMAxisLabel
// implementation before doing so.

@property (assign  , nonatomic) uint8_t dimensionIndex;
@property (assign  , nonatomic) uint8_t maxMajorTicks;

// FMAxisLabel use this property and 'checkIfMajorTickValueModified:' method to avoid redundant
// buffer updates.
@property (readonly, nonatomic) BOOL majorTickValueModified;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource;

// if majorTickValueModified is YES, then ifModified will be invoked, and clear the flag when YES is returned from it.
// return value of this method is identical to majorTickValueModified.
- (BOOL)checkIfMajorTickValueModified:(BOOL (^_Nonnull)(FMUniformAxisConfiguration *_Nonnull))ifModified;

@end

@interface FMUniformGridAttributes : NSObject

@property (readonly, nonatomic) id<MTLBuffer> _Nonnull buffer;
@property (readonly, nonatomic) uniform_grid_attributes * _Nonnull attributes;

@property (assign  , nonatomic) float anchorValue;
@property (assign  , nonatomic) float interval;
@property (assign  , nonatomic) uint8_t dimensionIndex;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

- (void)setWidth:(float)width;

- (void)setColorRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;
- (void)setColor:(vector_float4)color;
- (void)setColorRef:(vector_float4 const * _Nonnull)color;

- (void)setDepthValue:(float)depth;

- (void)setDashLineLength:(float)length;

- (void)setDashSpaceLength:(float)length;

- (void)setDashLineAnchor:(float)anchor;

- (void)setDashRepeatAnchor:(float)anchor;


@end

