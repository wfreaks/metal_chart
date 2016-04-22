//
//  RectBuffers.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/26.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import "Rect_common.h"
#import "Buffers.h"

@protocol MTLBuffer;

@interface FMUniformPlotRectAttributes : NSObject

@property (readonly, nonatomic) id<MTLBuffer> _Nonnull buffer;
@property (readonly, nonatomic) uniform_plot_rect * _Nonnull rect;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource;

- (void)setColorRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;
- (void)setColor:(vector_float4)color;
- (void)setColorRef:(vector_float4 const *_Nonnull)color;
- (void)setCornerRadius:(float)lt rt:(float)rt lb:(float)lb rb:(float)rb;
- (void)setCornerRadius:(float)radius;
- (void)setDepthValue:(float)value;

@end


@interface FMUniformBarConfiguration : NSObject

@property (readonly, nonatomic) id<MTLBuffer> _Nonnull buffer;
@property (readonly, nonatomic) uniform_bar_conf * _Nonnull conf;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource;

- (void)setDepthValue:(float)value;
- (void)setAnchorPoint:(CGPoint)point;
- (void)setBarDirection:(CGPoint)dir;

@end

@interface FMUniformBarAttributes : FMAttributesBuffer

@property (readonly, nonatomic) uniform_bar_attr * _Nonnull attr;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
                                     size:(NSUInteger)size
UNAVAILABLE_ATTRIBUTE;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource;

- (void)setColorRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;
- (void)setColor:(vector_float4)color;
- (void)setColorRef:(vector_float4 const *_Nonnull)color;
- (void)setCornerRadius:(float)radius;
- (void)setBarWidth:(float)width;

// 各頂点に個別の大きさを設定する. 注意すべきは、lt/rtがどこに来るかの自然な解釈が難しい事だ.
// 現状では, t/bはそれぞれ、(direction＋値の正負を考慮した)Barの伸展方向を上にした時の上下だが、
// l/rはbarDirectionを上にした時の右左である.
// 正直な所、名前を変えるべきか挙動を変えるべきか、判断がついていない.
// ただ、棒グラフとしては（機能の要不要は棚に上げると）この挙動が望ましいと考えている.
- (void)setCornerRadius:(float)lt rt:(float)rt lb:(float)lb rb:(float)rb;

@end


@interface FMUniformBarAttributesArray : FMAttributesArray<FMUniformBarAttributes*>

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
								 capacity:(NSUInteger)capacity
;

@end



