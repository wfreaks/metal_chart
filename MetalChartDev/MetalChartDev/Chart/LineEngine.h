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

@interface LineEngine : NSObject

@property (readonly, nonatomic) DeviceResource *resource;
@property (readonly, nonatomic) NSUInteger capacity;

- (id)initWithResource:(DeviceResource *)resource
		bufferCapacity:(NSUInteger)capacity;


- (void)encodeTo:(id<MTLCommandBuffer>)command
			pass:(MTLRenderPassDescriptor *)pass
	 sampleCount:(NSUInteger)count
		  format:(MTLPixelFormat)format
			size:(CGSize)size;

- (void)encodeTo:(id<MTLCommandBuffer>)command
            pass:(MTLRenderPassDescriptor *)pass
          vertex:(VertexBuffer *)vertex
           index:(IndexBuffer *)index
      projection:(UniformProjection *)projection
      attributes:(UniformLineAttributes *)attributes
      seriesInfo:(UniformSeriesInfo *)info
;

@end
