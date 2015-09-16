//
//  TextureQuadBuffers.h
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/09/16.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>

#import "TextureQuad_common.h"

@class DeviceResource;
@protocol MTLBuffer;

@interface UniformRegion : NSObject

@property (readonly, nonatomic) id<MTLBuffer> _Nonnull buffer;
@property (readonly, nonatomic) uniform_region * _Nonnull region;

- (instancetype _Null_unspecified)initWithResource:(DeviceResource * _Nonnull)resource;

- (void)setBasePosition:(CGPoint)point;
- (void)setAnchorPoint:(CGPoint)anchor;
- (void)setSize:(CGSize)size;
- (void)setIterationVector:(CGPoint)vec;
- (void)setIterationOffset:(CGFloat)offset;

@end

