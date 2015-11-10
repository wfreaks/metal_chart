//
//  PolyLines.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/06.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import "Protocols.h"

@class FMEngine;
@class FMUniformProjectionCartesian2D;
@class FMUniformLineAttributes;
@class FMUniformAxisConfiguration;
@class FMUniformAxisAttributes;
@class UniformPointAttributes;
@class FMUniformGridAttributes;
@class OrderedSeries;
@class IndexedSeries;

@protocol Series;

@interface LinePrimitive : NSObject<Primitive>

@property (strong  , nonatomic) FMUniformLineAttributes * _Nonnull attributes;
@property (strong  , nonatomic) UniformPointAttributes * _Nullable pointAttributes;
@property (readonly, nonatomic) FMEngine * _Nonnull engine;

- (id<Series> _Nullable)series;

@end



// 使い所がなくてメンテが滞っている、正常動作しない可能性が高い.
@interface OrderedSeparatedLinePrimitive : LinePrimitive

@property (strong, nonatomic) OrderedSeries * _Nullable series;

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
								   orderedSeries:(OrderedSeries * _Nullable)series
									  attributes:(FMUniformLineAttributes * _Nullable)attributes
;

@end


@interface PolyLinePrimitive : LinePrimitive

@end

@interface OrderedPolyLinePrimitive : PolyLinePrimitive

@property (strong, nonatomic) OrderedSeries * _Nullable series;

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
								   orderedSeries:(OrderedSeries * _Nullable)series
									  attributes:(FMUniformLineAttributes * _Nullable)attributes
;

- (void)appendSampleData:(NSUInteger)count
		  maxVertexCount:(NSUInteger)maxCount
                    mean:(CGFloat)mean
                variance:(CGFloat)variant
			  onGenerate:(void (^_Nullable)(float x, float y))block
;

@end


@interface Axis : NSObject

@property (readonly, nonatomic) FMUniformAxisConfiguration * _Nonnull configuration;
@property (readonly, nonatomic) FMUniformAxisAttributes * _Nonnull axisAttributes;
@property (readonly, nonatomic) FMUniformAxisAttributes * _Nonnull majorTickAttributes;
@property (readonly, nonatomic) FMUniformAxisAttributes * _Nonnull minorTickAttributes;

@property (readonly, nonatomic) FMEngine * _Nonnull engine;

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
;

- (void)encodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
        projection:(FMUniformProjectionCartesian2D * _Nonnull)projection
     maxMajorTicks:(NSUInteger)maxCount
;

@end


@interface GridLine : NSObject

@property (readonly, nonatomic) FMUniformGridAttributes * _Nonnull attributes;

@property (readonly, nonatomic) FMEngine * _Nonnull engine;

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

- (void)encodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
        projection:(FMUniformProjectionCartesian2D * _Nonnull)projection
          maxCount:(NSUInteger)maxCount
;


@end



