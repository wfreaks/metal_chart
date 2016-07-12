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

/**
 * FMSeries represents sereis of plain data (not associated with any visual attributes or presentation style).
 * It does not tell anything about underlying element format.
 * It provides : 
 *
 * 1. MTLBuffer object to be passed to render command encoder.
 * 2. series info for determining primitive count to draw on issueing command.
 * 3. abstracted methods for putting data (but actually it's useless for attributed data, so use one that is provided by a derived/concrete class in that case).
 * 4. a method for extending buffer capacity.
 */

@protocol FMSeries<NSObject>

- (id<MTLBuffer> _Nonnull)vertexBuffer;
- (FMUniformSeriesInfo * _Nonnull)info;

- (void)addPoint:(CGPoint)point;

/**
 * increment offset if info.count >= info.capacity.
 */
- (void)addPoint:(CGPoint)point maxCount:(NSUInteger)max;

/**
 * mimics std::vector<T>::reserve().
 * should not be used with cyclic accessed buffers (offset >= capacity).
 * this operation involves allocating, copying, and deallocating so avoid incremental extension.
 */
- (void)reserve:(NSUInteger)capacity;

@end

/**
 * reprensents a series of non-attributed, ordered data.
 * use addPoint: to add a data point.
 */

@interface FMOrderedSeries : NSObject<FMSeries>

@property (readonly, nonatomic) FMFloat2Buffer * _Nonnull vertices;
@property (readonly, nonatomic) FMUniformSeriesInfo * _Nonnull info;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
						   vertexCapacity:(NSUInteger)vertCapacity
;

@end

/**
 * reprensents a series of attributed, ordered data.
 * use addPoint:attrIndex: to add a data point.
 */

@interface FMOrderedAttributedSeries : NSObject<FMSeries>

@property (readonly, nonatomic) FMIndexedFloat2Buffer * _Nonnull vertices;
@property (readonly, nonatomic) FMUniformSeriesInfo * _Nonnull info;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
						   vertexCapacity:(NSUInteger)vertCapacity
;

- (void)addPoint:(CGPoint)point attrIndex:(NSUInteger)attrIndex;

/**
 * increment offset if info.count >= info.capacity.
 */
- (void)addPoint:(CGPoint)point maxCount:(NSUInteger)max attrIndex:(NSUInteger)attrIndex;

@end


#endif
