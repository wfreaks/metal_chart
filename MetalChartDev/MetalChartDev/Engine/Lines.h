//
//  PolyLines.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/06.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Engine.h"
#import "Buffers.h"
#import "LineBuffers.h"
#import "Series.h"

@interface Line : NSObject

@property (readonly, nonatomic) id<Series> _Nonnull series;
@property (strong  , nonatomic) UniformLineAttributes * _Nonnull attributes;
@property (readonly, nonatomic) Engine * _Nonnull engine;

- (void)encodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
		projection:(UniformProjection * _Nonnull)projection
;

- (void)setSampleAttributes;

@end




@interface OrderedSeparatedLine : Line

- (instancetype _Null_unspecified)initWithEngine:(Engine * _Nonnull)engine
								   orderedSeries:(OrderedSeries * _Nonnull)series
;

@end


@interface PolyLine : Line
@end

@interface OrderedPolyLine : PolyLine

- (instancetype _Null_unspecified)initWithEngine:(Engine * _Nonnull)engine
								   orderedSeries:(OrderedSeries * _Nonnull)series
;

- (void)setSampleData;

- (void)appendSampleData:(NSUInteger)count
		  maxVertexCount:(NSUInteger)maxCount
                    mean:(CGFloat)mean
                variance:(CGFloat)variant
			  onGenerate:(void (^_Nullable)(float x, float y))block
;

@end


@interface IndexedPolyLine : PolyLine

- (instancetype _Null_unspecified)initWithEngine:(Engine * _Nonnull)engine
								   indexedSeries:(IndexedSeries * _Nonnull)series
;

@end


@interface Axis : NSObject

@property (readonly, nonatomic) UniformAxis * _Nonnull uniform;
@property (readonly, nonatomic) Engine * _Nonnull engine;

- (instancetype _Null_unspecified)initWithEngine:(Engine * _Nonnull)engine
;

- (void)encodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
        projection:(UniformProjection * _Nonnull)projection
;

@end

