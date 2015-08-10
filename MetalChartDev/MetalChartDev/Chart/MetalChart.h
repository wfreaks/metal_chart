//
//  MetalChart.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/09.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>

@class UniformProjection;

@protocol MCRenderable <NSObject>

- (void)renderWithCommandBuffer:(id<MTLCommandBuffer> _Nonnull)buffer
					 renderPass:(MTLRenderPassDescriptor * _Nonnull)pass
					 projection:(UniformProjection * _Nonnull)projection
;

@end


@interface MCDimProjection : NSObject

@property (readonly, nonatomic) NSInteger dimensionId;
@property (assign  , nonatomic) CGFloat     min;
@property (assign  , nonatomic) CGFloat     max;
@property (copy    , nonatomic) void (^ _Nullable willUpdate)(CGFloat * _Nullable newMin, CGFloat * _Nullable newMax);

- (_Null_unspecified instancetype)initWithDimensionId:(NSInteger)dimId
											 minValue:(CGFloat)min
											 maxValue:(CGFloat)max
;

- (void)setMin:(CGFloat)min max:(CGFloat)max;

@end


@interface MCSpaceProjection : NSObject

@property (readonly, nonatomic) NSArray<MCDimProjection *> * _Nonnull dimensions;

- (_Null_unspecified instancetype)initWithDimensions:(NSArray<MCDimProjection *> * _Nonnull)dimensions;

- (NSUInteger)rank;

- (void)writeToBuffer;

- (void)configure:(MTKView * _Nonnull)view;

@end


@interface MetalChart : NSObject<MTKViewDelegate>

- (_Null_unspecified instancetype)init;

- (void)addSeries:(id<MCRenderable> _Nonnull)series
	   projection:(MCSpaceProjection * _Nonnull)projection
;

- (void)removeSeries:(id<MCRenderable> _Nonnull)series;

- (NSArray<id<MCRenderable>> * _Nonnull)series;

- (NSArray<MCSpaceProjection *> * _Nonnull)projections;

@end
