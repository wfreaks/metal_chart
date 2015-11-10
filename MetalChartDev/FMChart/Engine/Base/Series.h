//
//  Series.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/11.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Buffers.h"

#ifndef __Series_h__
#define __Series_h__

@protocol Series<NSObject>

- (id<MTLBuffer> _Nonnull)vertexBuffer;
- (FMUniformSeriesInfo * _Nonnull)info;

- (void)addPoint:(CGPoint)point; // increment count.
- (void)addPoint:(CGPoint)point maxCount:(NSUInteger)max; // increment offset if info.count has reached max.

@end

@interface FMOrderedSeries : NSObject<Series>

@property (readonly, nonatomic) VertexBuffer * _Nonnull vertices;
@property (readonly, nonatomic) FMUniformSeriesInfo * _Nonnull info;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
									vertexCapacity:(NSUInteger)vertCapacity
;

@end

@interface FMIndexedSeries : NSObject<Series>

@property (readonly, nonatomic) VertexBuffer * _Nonnull vertices;
@property (readonly, nonatomic) IndexBuffer * _Nonnull indices;
@property (readonly, nonatomic) FMUniformSeriesInfo * _Nonnull info;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
									vertexCapacity:(NSUInteger)vertCapacity
									 indexCapacity:(NSUInteger)idxCapacity
;

// write vertices[index] = point, indices[head] = index;
- (void)addPoint:(CGPoint)point
		 atIndex:(NSUInteger)index
		maxCount:(NSUInteger)max; 
@end

#endif
