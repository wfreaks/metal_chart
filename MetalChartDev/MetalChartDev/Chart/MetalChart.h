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


@interface MCDimensionalProjection : NSObject

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


@interface MCSpatialProjection : NSObject

@property (readonly, nonatomic) NSArray<MCDimensionalProjection *> * _Nonnull dimensions;

- (_Null_unspecified instancetype)initWithDimensions:(NSArray<MCDimensionalProjection *> * _Nonnull)dimensions;

- (NSUInteger)rank;

- (void)writeToBuffer;

- (void)configure:(MTKView * _Nonnull)view;

@end


@interface MetalChart : NSObject<MTKViewDelegate>

@property (copy, nonatomic) void (^ _Nullable willDraw)(MetalChart * _Nonnull);
@property (copy, nonatomic) void (^ _Nullable didDraw)(MetalChart * _Nonnull);

- (_Null_unspecified instancetype)init;

- (void)addSeries:(id<MCRenderable> _Nonnull)series
	   projection:(MCSpatialProjection * _Nonnull)projection
;

- (void)removeSeries:(id<MCRenderable> _Nonnull)series;

- (NSArray<id<MCRenderable>> * _Nonnull)series;

- (NSArray<MCSpatialProjection *> * _Nonnull)projections;

- (void)addToPanRecognizer:(UIPanGestureRecognizer * _Nonnull)recognizer;
- (void)removeFromPanRecognizer:(UIPanGestureRecognizer * _Nonnull)recognizer;

- (void)addToPinchRecognizer:(UIPinchGestureRecognizer * _Nonnull)recognizer;
- (void)removeFromPinchRecognizer:(UIPinchGestureRecognizer * _Nonnull)recognizer;

@end
