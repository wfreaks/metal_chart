//
//  Series.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/11.
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

// see std::vector<T>::reserve().
// should not be used with cyclic accessed buffers.
// this operation involves allocating, copying, and deallocating, and its cost is high.
- (void)reserve:(NSUInteger)capacity;

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


#endif
