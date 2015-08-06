//
//  PolyLines.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/06.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Buffers.h"

@interface IndexedPolyLine : NSObject

@property (readonly, nonatomic) VertexBuffer *vertices;
@property (readonly, nonatomic) IndexBuffer *indices;
@property (readonly, nonatomic) UniformSeriesInfo *info;
@property (strong  , nonatomic) UniformLineAttributes *attributes;

- (id)initWithResource:(DeviceResource *)resource
		VertexCapacity:(NSUInteger)vertCapacity
		 indexCapacity:(NSUInteger)idxCapacity
;

- (void)setSampleData;

@end
