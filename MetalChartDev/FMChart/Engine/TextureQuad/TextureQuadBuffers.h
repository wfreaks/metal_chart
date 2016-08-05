//
//  TextureQuadBuffers.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/09/16.
//  Copyright © 2015 Keisuke Mori. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import "TextureQuad_common.h"
#import "Prototypes.h"

@protocol MTLBuffer;

/**
 * FMUniformRegion is a wrapper class for struct uniform_region that provides setter methods.
 *
 * an anchor position for region idx is defined by :
 * pos_anchor(idx) = basePosition + ((iterationOffset + idx) * iterationVector)
 *
 * and region frame is defined by : 
 * (origin, size) = (pos_anchor + positionOffset + (anchorPoint-center) * size), size).
 * where center = (0.5, 0.5).
 *
 * note : size and positionOffset for FMTextureQuadPrimitive.dataRegion are treated as view(logical pixel) size and offset.
 * this strage behavior is to allow FMAxisLabel to perform effective processing.
 * you must write an alternative shader and subclass FMTextureQuadPrimitive to replace it to change the behavior.
 */

@interface FMUniformRegion : NSObject

@property (readonly, nonatomic) id<MTLBuffer> _Nonnull buffer;
@property (readonly, nonatomic) uniform_region * _Nonnull region;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource;

- (void)setBasePosition:(CGPoint)point;
- (void)setAnchorPoint:(CGPoint)anchor;
- (void)setIterationVector:(CGPoint)vec;
- (void)setIterationOffset:(CGFloat)offset;

/**
 * Interpretation of size is shader-dependent.
 * uv size in texture space (for texRegion), and logical pixels otherwise (for dataRegion)
 */
- (void)setSize:(CGSize)size;

/**
 * Interpretation of positionOffset is shader-dependent.
 * uv size in texture space (for texRegion), and in view-coordinate system otherwise (for dataRegion)
 */
- (void)setPositionOffset:(CGPoint)offset;


@end

