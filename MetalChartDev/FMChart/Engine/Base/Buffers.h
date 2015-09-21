 //
//  VertexBuffer.h
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/08/05.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import <Metal/Metal.h>
#import "Line_common.h"
#import "DeviceResource.h"

#ifndef __Buffers_h__
#define __Buffers_h__

#ifdef __cplusplus

#include <memory>

#endif

@interface VertexBuffer : NSObject

@property (readonly, nonatomic) id<MTLBuffer> _Nonnull buffer;

@property (readonly, nonatomic) NSUInteger capacity;

// このoriginはMetalの座標系NDC([-1,1]x[-1,1])の中での点を指定する.この点にInputの(0, 0)が描画される.
@property (assign, nonatomic) CGPoint origin;

@property (assign, nonatomic) CGSize scale;

- (instancetype _Nonnull)initWithResource:(DeviceResource * _Nonnull)resource capacity:(NSUInteger)capacity;

- (vertex_buffer * _Nonnull)bufferAtIndex:(NSUInteger)index;

#ifdef __cplusplus

- (std::shared_ptr<vertex_container>)container;

#endif

@end






@interface IndexBuffer : NSObject

@property (readonly, nonatomic) id<MTLBuffer> _Nonnull buffer;
@property (readonly, nonatomic) NSUInteger capacity;

- (instancetype _Nonnull)initWithResource:(DeviceResource * _Nonnull)resource capacity:(NSUInteger)capacity;

- (index_buffer * _Nonnull)bufferAtIndex:(NSUInteger)index;

#ifdef __cplusplus

- (std::shared_ptr<index_container>)container;

#endif

@end





// このクラスだけScissorRectやらscreenScaleやらを考慮した上でvalueOffsetとかsizeとvalueScaleを
// 設定しなければいけないので煩雑になる。

@interface UniformProjection : NSObject

@property (readonly, nonatomic) id<MTLBuffer> _Nonnull buffer;
@property (readonly, nonatomic) CGFloat screenScale;
@property (assign, nonatomic) NSUInteger sampleCount;
@property (assign, nonatomic) MTLPixelFormat colorPixelFormat;
@property (assign, nonatomic) CGSize physicalSize;
@property (assign, nonatomic) RectPadding padding;
@property (assign, nonatomic) BOOL enableScissor;

- (instancetype _Nonnull)initWithResource:(DeviceResource * _Nonnull)resource;

- (uniform_projection * _Nonnull)projection;

- (void)setPixelSize:(CGSize)size;

- (void)setValueScale:(CGSize)scale;

- (void)setOrigin:(CGPoint)origin;

- (void)setValueOffset:(CGSize)offset;

@end





@interface UniformSeriesInfo : NSObject

@property (readonly, nonatomic) id<MTLBuffer> _Nonnull buffer;
@property (assign, nonatomic) NSUInteger count;
@property (assign, nonatomic) NSUInteger offset;

- (instancetype _Nonnull)initWithResource:(DeviceResource * _Nonnull)resource;

- (uniform_series_info * _Nonnull)info;

@end


#endif
