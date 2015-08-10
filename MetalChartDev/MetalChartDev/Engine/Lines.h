//
//  PolyLines.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/06.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LineEngine.h"
#import "Buffers.h"
#import "Series.h"

@interface Line : NSObject

@property (readonly, nonatomic) id<Series> _Nonnull series;
@property (strong  , nonatomic) UniformLineAttributes * _Nonnull attributes;
@property (readonly, nonatomic) LineEngine * _Nonnull engine;

- (void)encodeTo:(id<MTLCommandBuffer> _Nonnull)command
      renderPass:(MTLRenderPassDescriptor * _Nonnull)pass
      projection:(UniformProjection * _Nonnull)projection
;

- (void)setSampleAttributes;

- (void)setSampleData;

- (void)appendSampleData:(NSUInteger)count
		  maxVertexCount:(NSUInteger)maxCount
			  onGenerate:(void (^_Nullable)(float x, float y))block
;

@end




@interface OrderedSeparatedLine : Line

- (_Null_unspecified instancetype)initWithResource:(DeviceResource * _Nonnull)resource
									 orderedSeries:(OrderedSeries * _Nonnull)series
											engine:(LineEngine * _Nonnull)engine
;

@end





@interface OrderedPolyLine : Line

- (_Null_unspecified instancetype)initWithResource:(DeviceResource * _Nonnull)resource
									 orderedSeries:(OrderedSeries * _Nonnull)series
											engine:(LineEngine * _Nonnull)engine
;

@end




@interface IndexedPolyLine : Line

- (_Null_unspecified instancetype)initWithResource:(DeviceResource * _Nonnull)resource
									 indexedSeries:(IndexedSeries * _Nonnull)series
											engine:(LineEngine * _Nonnull)engine
;


@end
