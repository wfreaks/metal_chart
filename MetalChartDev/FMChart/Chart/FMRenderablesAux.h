//
//  FMRenderablesAux.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/11/18.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MetalChart.h"

/*
 * 通常のRenderableと違って、ほとんどGPU側で仕事をするプリミティブだけでは対応できないような、
 * 面倒なものをこちらに突っ込む. C++を使う事を余儀なくされるものもこちら.
 *
 */


@class FMEngine;
@class FMProjectionPolar;
@class FMIndexedFloatBuffer;
@class FMContinuosArcPrimitive;
@class FMUniformSeriesInfo;
@class FMUniformArcAttributesArray;
@class FMUniformArcConfiguration;

@class FMPieDoughnutSeries;

typedef struct PieProxyElement {
	NSInteger dataID; // IDはユニークである必要はない.
	CGFloat   value;
	uint32_t  index;
#ifdef __cplusplus
	PieProxyElement(NSInteger _id, CGFloat v, uint32_t idx) :
	dataID(_id), value(v), index(idx)
	{}
#endif
} FMPieDoughnutDataProxyElement;

@interface FMPieDoughnutDataProxy : NSObject


@property (nonatomic, readonly) FMPieDoughnutSeries * _Nonnull series;

- (instancetype _Nonnull)init
UNAVAILABLE_ATTRIBUTE;

- (FMPieDoughnutDataProxyElement * _Nullable)elementWithID:(NSInteger)_id;

// IDはユニークでなくても良い(後から参照できなくなるだけ)
- (void)addElementWithValue:(CGFloat)value
					  index:(uint32_t)index
						 ID:(NSInteger)_id
;

- (void)removeElementWithID:(NSInteger)_id;
- (void)clear;

- (void)sort:(BOOL)ascend;

- (void)flush;

@end


@interface FMPieDoughnutSeries : NSObject <FMRenderable>

@property (nonatomic, readonly) FMContinuosArcPrimitive * _Nonnull arc;
@property (nonatomic, readonly) FMUniformArcConfiguration * _Nonnull conf;
@property (nonatomic, readonly) FMUniformArcAttributesArray * _Nonnull attrs;
@property (nonatomic, readonly) FMIndexedFloatBuffer * _Nonnull values;
@property (nonatomic)			FMProjectionPolar * _Nullable projection;
@property (nonatomic)			NSUInteger offset;
@property (nonatomic)			NSUInteger count;
@property (nonatomic, readonly) NSUInteger capacity;

@property (nonatomic, readonly) FMPieDoughnutDataProxy * _Nonnull data;

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
									arc:(FMContinuosArcPrimitive * _Nullable)arc
							 projection:(FMProjectionPolar * _Nullable)projection
								 values:(FMIndexedFloatBuffer * _Nullable)values
			 attributesCapacityOnCreate:(NSUInteger)attrCapacity
				 valuesCapacityOnCreate:(NSUInteger)valueCapacity
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init
UNAVAILABLE_ATTRIBUTE;

@end

