//
//  FMRenderablesAux.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/11/18.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MetalChart.h"

/**
 * FMPieDoughnutDataProxyElement is a struct that represents an element of pie doughnut chart
 * used by FMPieDoughnutDataProxy.
 * value represents a data value, which is need to be converted to ratio it occupies in major usecase.
 * index represents an attribute index you want to use to show the element (colors and radius).
 * dataID is an id number you need to specify to modify/remove after insertion. (you can ignore it if you do not need to perform these operations)
 */

typedef struct FMPieDoughnutDataProxyElement {
	NSInteger dataID;
	CGFloat   value;
	uint32_t  index;
#ifdef __cplusplus
	FMPieDoughnutDataProxyElement(NSInteger _id, CGFloat v, uint32_t idx) :
	dataID(_id), value(v), index(idx)
	{}
#endif
} FMPieDoughnutDataProxyElement;

/**
 * FMPieDoughnutDataProxy provides a simple way to use FMContinuousArcPrimitive,
 * which is a bit hard to use directly in application codes (see Engine/Circle/Circles.h for details).
 *
 * Do not forget to flush data after modification (It has its own buffer on host/cpu side).
 */

@interface FMPieDoughnutDataProxy : NSObject

@property (nonatomic, weak, readonly) FMPieDoughnutSeries * _Nullable series;

- (instancetype _Nonnull)init
UNAVAILABLE_ATTRIBUTE;

- (FMPieDoughnutDataProxyElement * _Nullable)elementWithID:(NSInteger)_id;

- (void)addElementWithValue:(CGFloat)value
					  index:(uint32_t)index
						 ID:(NSInteger)_id
;

- (void)removeElementWithID:(NSInteger)_id;
- (void)clear;

- (void)sort:(BOOL)ascend;

- (void)flush;

@end

/**
 * A class to present pie/doughnut chart.
 *
 * 1. set up attributes array to change colors and radius.
 * 2. put data using data property (proxy object) and flush it to value buffer.
 *    (do not modify values property directly when you use proxy object. proxy object writes data into value property)
 * 3. add to a chart.
 * 
 * you can ignore conf property in most cases (attributes override conflicting prpperties if its values are valid).
 */

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

