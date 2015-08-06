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
#import "LineEngine_common.h"
#import "DeviceResource.h"

#ifdef __cplusplus

#include <memory>

#endif

@interface VertexBuffer : NSObject

@property (readonly, nonatomic) id<MTLBuffer> buffer;

@property (readonly, nonatomic) NSUInteger capacity;

// このoriginはMetalの座標系NDC([-1,1]x[-1,1])の中での点を指定する.この点にInputの(0, 0)が描画される.
@property (assign, nonatomic) CGPoint origin;

@property (assign, nonatomic) CGSize scale;

- (id)initWithResource:(DeviceResource *)resource capacity:(NSUInteger)capacity;

- (vertex_buffer *)bufferAtIndex:(NSUInteger)index;

#ifdef __cplusplus

- (std::shared_ptr<vertex_container>)container;

#endif

@end






@interface IndexBuffer : NSObject

@property (readonly, nonatomic) id<MTLBuffer> buffer;
@property (readonly, nonatomic) NSUInteger capacity;

- (id)initWithResource:(DeviceResource *)resource capacity:(NSUInteger)capacity;

- (index_buffer *)bufferAtIndex:(NSUInteger)index;

#ifdef __cplusplus

- (std::shared_ptr<index_container>)container;

#endif

@end






@interface UniformProjection : NSObject

@property (readonly, nonatomic) id<MTLBuffer> buffer;
@property (assign, nonatomic) NSUInteger sampleCount;
@property (assign, nonatomic) MTLPixelFormat colorPixelFormat;

- (id)initWithResource:(DeviceResource *)resource;

- (uniform_projection *)projection;

- (void)setPhysicalSize:(CGSize)size;

- (void)setValueScale:(CGSize)scale;

- (void)setOrigin:(CGPoint)origin;

- (void)setValueOffset:(CGSize)offset;

@end






@interface UniformLineAttributes : NSObject

@property (readonly, nonatomic) id<MTLBuffer> buffer;
@property (assign, nonatomic) BOOL enableOverlay;

- (id)initWithResource:(DeviceResource *)resource;

- (uniform_line_attr *)attributes;

- (void)setWidth:(CGFloat)width;
- (void)setColorWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;
- (void)setModifyAlphaOnEdge:(BOOL)modify;

@end






@interface UniformSeriesInfo : NSObject

@property (readonly, nonatomic) id<MTLBuffer> buffer;
@property (assign, nonatomic) NSUInteger count;
@property (assign, nonatomic) NSUInteger offset;

- (id)initWithResource:(DeviceResource *)resource;

- (uniform_series_info *)info;

@end








