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

@protocol FMSeries<NSObject>

- (id<MTLBuffer> _Nonnull)vertexBuffer;
- (FMUniformSeriesInfo * _Nonnull)info;

- (void)addPoint:(CGPoint)point; // increment count.
- (void)addPoint:(CGPoint)point maxCount:(NSUInteger)max; // increment offset if info.count has reached max.

@end

@interface FMOrderedSeries : NSObject<FMSeries>

@property (readonly, nonatomic) VertexBuffer * _Nonnull vertices;
@property (readonly, nonatomic) FMUniformSeriesInfo * _Nonnull info;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
						   vertexCapacity:(NSUInteger)vertCapacity
;

@end

@interface FMOrderedAttributedSeries : NSObject<FMSeries>

@property (readonly, nonatomic) FMIndexedFloat2Buffer * _Nonnull vertices;
@property (readonly, nonatomic) FMUniformSeriesInfo * _Nonnull info;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
						   vertexCapacity:(NSUInteger)vertCapacity
;

- (void)addPoint:(CGPoint)point attrIndex:(NSUInteger)attrIndex;
- (void)addPoint:(CGPoint)point maxCount:(NSUInteger)max attrIndex:(NSUInteger)attrIndex;

@end

// これは、「描画するデータを指定するための」index. 属性を指定するためのそれと区別する事.

@interface FMIndexedSeries : NSObject<FMSeries>

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
