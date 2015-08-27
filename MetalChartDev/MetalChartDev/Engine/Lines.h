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

@class Engine;
@class UniformProjection;
@class UniformLineAttributes;
@class UniformAxis;
@class OrderedSeries;
@class IndexedSeries;

@protocol Series;

@interface LinePrimitive : NSObject<Primitive>

@property (strong  , nonatomic) UniformLineAttributes * _Nonnull attributes;
@property (readonly, nonatomic) Engine * _Nonnull engine;

- (void)setSampleAttributes;

- (id<Series> _Nullable)series;

@end




@interface OrderedSeparatedLinePrimitive : LinePrimitive

- (instancetype _Null_unspecified)initWithEngine:(Engine * _Nonnull)engine
								   orderedSeries:(OrderedSeries * _Nullable)series
;

@end


@interface PolyLinePrimitive : LinePrimitive
@end

@interface OrderedPolyLinePrimitive : PolyLinePrimitive

- (instancetype _Null_unspecified)initWithEngine:(Engine * _Nonnull)engine
								   orderedSeries:(OrderedSeries * _Nullable)series
;

- (void)setSampleData;

- (void)appendSampleData:(NSUInteger)count
		  maxVertexCount:(NSUInteger)maxCount
                    mean:(CGFloat)mean
                variance:(CGFloat)variant
			  onGenerate:(void (^_Nullable)(float x, float y))block
;

@end


@interface IndexedPolyLinePrimitive : PolyLinePrimitive

- (instancetype _Null_unspecified)initWithEngine:(Engine * _Nonnull)engine
								   indexedSeries:(IndexedSeries * _Nullable)series
;

@end


@interface Axis : NSObject

@property (readonly, nonatomic) UniformAxis * _Nonnull attributes;
@property (readonly, nonatomic) Engine * _Nonnull engine;

- (instancetype _Null_unspecified)initWithEngine:(Engine * _Nonnull)engine
;

- (void)encodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
        projection:(UniformProjection * _Nonnull)projection
;

@end

