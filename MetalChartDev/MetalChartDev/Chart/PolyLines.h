//
//  PolyLines.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/06.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LineEngine.h"
#import "Buffers.h"

@interface Line : NSObject

@property (readonly, nonatomic) VertexBuffer *vertices;
@property (strong  , nonatomic) UniformLineAttributes *attributes;
@property (readonly, nonatomic) UniformSeriesInfo *info;

- (id)initWithResource:(DeviceResource *)resource
        vertexCapacity:(NSUInteger)vertCapacity;

- (void)encodeTo:(id<MTLCommandBuffer>)command
      renderPass:(MTLRenderPassDescriptor *)pass
      projection:(UniformProjection *)projection
          engine:(LineEngine *)engine
;

@end

@interface OrderedPolyLine : Line

- (void)setSampleData;

@end

@interface IndexedPolyLine : Line

@property (readonly, nonatomic) IndexBuffer *indices;

- (id)initWithResource:(DeviceResource *)resource
		VertexCapacity:(NSUInteger)vertCapacity
		 indexCapacity:(NSUInteger)idxCapacity
;

- (void)setSampleData;


@end
