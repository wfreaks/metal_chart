//
//  Series.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/11.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Buffers.h"

@protocol Series<NSObject>

- (id<MTLBuffer> _Nonnull)vertexBuffer;
- (UniformSeriesInfo * _Nonnull)info;

@end

@interface OrderedSeries : NSObject<Series>

@property (readonly, nonatomic) VertexBuffer * _Nonnull vertices;
@property (readonly, nonatomic) UniformSeriesInfo * _Nonnull info;

- (instancetype _Null_unspecified)initWithResource:(DeviceResource * _Nonnull)resource
									vertexCapacity:(NSUInteger)vertCapacity
;

- (void)addPoint:(CGPoint)point; // increment count.
- (void)addPoint:(CGPoint)point maxCount:(NSUInteger)max; // increment offset if info.count has reached max.

@end

@interface IndexedSeries : NSObject<Series>

@property (readonly, nonatomic) VertexBuffer * _Nonnull vertices;
@property (readonly, nonatomic) IndexBuffer * _Nonnull indices;
@property (readonly, nonatomic) UniformSeriesInfo * _Nonnull info;

- (instancetype _Null_unspecified)initWithResource:(DeviceResource * _Nonnull)resource
									vertexCapacity:(NSUInteger)vertCapacity
									 indexCapacity:(NSUInteger)idxCapacity
;


@end
