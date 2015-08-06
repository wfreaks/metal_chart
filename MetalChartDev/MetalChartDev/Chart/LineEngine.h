//
//  LineEngine.h
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/08/03.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "DeviceResource.h"
#import <CoreGraphics/CoreGraphics.h>
#import "Buffers.h"

@class IndexedPolyLine;

@interface LineEngine : NSObject

@property (readonly, nonatomic) DeviceResource *resource;

- (id)initWithResource:(DeviceResource *)resource
;

- (void)encodeTo:(id<MTLCommandBuffer>)command
            pass:(MTLRenderPassDescriptor *)pass
          vertex:(VertexBuffer *)vertex
           index:(IndexBuffer *)index
      projection:(UniformProjection *)projection
      attributes:(UniformLineAttributes *)attributes
      seriesInfo:(UniformSeriesInfo *)info
;

- (void)encodeTo:(id<MTLCommandBuffer>)command
            pass:(MTLRenderPassDescriptor *)pass
     indexedLine:(IndexedPolyLine *)line
      projection:(UniformProjection *)projection;
;

@end

