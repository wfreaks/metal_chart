//
//  LineBuffers.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/25.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import "Line_common.h"
#import "Buffers.h"

@protocol MTLBuffer;

@interface FMUniformLineAttributes : FMAttributesBuffer

@property (readonly, nonatomic) uniform_line_attr * _Nonnull attributes;

// 破線処理を考慮したシェーダは考慮しないものと比較するとGPU負荷が1.5倍程度になるので、
// 明示的に切り替え用のフラグを用意する.
@property (assign, nonatomic) BOOL enableDash;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
                                     size:(NSUInteger)size
UNAVAILABLE_ATTRIBUTE;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource;

- (void)setWidth:(float)width;

- (void)setColorRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;
- (void)setColor:(vector_float4)color;
- (void)setColorRef:(vector_float4 const * _Nonnull)color;

- (void)setLineLengthModifierStart:(float)start end:(float)end;

// 以下破線用の属性, lengthはすべてwidthとの関係で実際の長さが決まる(数値としては形状を決めるためのもの)
// dashLineLengthは破線のうち描画される部分のキャップを除いた部分の長さ.
// 0以下の値を設定するとフォールバックして直線となり, 微小な正の値を設定すると点線, 0.5で前述の点の半径だけ直線部分が現れる.
// dashSpaceLengthは同じ単位で空白を表す, 0だと破線間がほぼ隣接し, 0.5で同様に点半径だけ間隔が空く.
- (void)setDashLineLength:(float)length;

- (void)setDashSpaceLength:(float)length;

// 以下のanchorは線長と繰り返し長が一致しない時（がほぼすべてだが）に繰り返し範囲内のどの点を線内のどの点に配置するかを指定する属性.
// dashLineAnchorは、線長の[-1,1]の範囲を指定する. 0が中央, -1,1は始点,終点 別に範囲外を指定しても良い.
- (void)setDashLineAnchor:(float)anchor;
// dashRepeatAnchorは繰り返し範囲の[-1,1]を指定する. -1,1は空白に当たり, 0は実線の中央に該当する.
- (void)setDashRepeatAnchor:(float)anchor;

@end



@interface FMUniformLineAttributesArray : FMAttributesArray<FMUniformLineAttributes*>

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
								 capacity:(NSUInteger)capacity
NS_DESIGNATED_INITIALIZER;

@end




@interface FMUniformLineConf : NSObject

@property (readonly, nonatomic) id<MTLBuffer> _Nonnull buffer;
@property (readonly, nonatomic) uniform_line_conf * _Nonnull conf;

@property (assign, nonatomic) BOOL enableOverlay;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource;

- (void)setAlpha:(float)alpha;

- (void)setDepthValue:(float)depth;

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

@property (assign  , nonatomic) float axisAnchorDataValue;
@property (assign  , nonatomic) float axisAnchorNDCValue; // [-1, 1], この値の外ではDataValueが使われる
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

- (float)axisAnchorValueWithProjection:(FMUniformProjectionCartesian2D * _Nonnull)projection;

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

