//
//  MetalChart.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/09.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>
#import "LineEngine_common.h"

@class UniformProjection;
@class MetalChart;

@protocol MCRenderable <NSObject>

- (void)encodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
		projection:(UniformProjection * _Nonnull)projection
;

@end



@protocol MCPreRenderable <NSObject>

- (void)willEncodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
				 chart:(MetalChart * _Nonnull)chart
				  view:(MTKView * _Nonnull)view
;

@end



@protocol MCPostRenderable <NSObject>

- (void)didEncodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
				chart:(MetalChart * _Nonnull)chart
				 view:(MTKView * _Nonnull)view
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

- (CGFloat)length;

@end


@interface MCSpatialProjection : NSObject

@property (readonly, nonatomic) NSArray<MCDimensionalProjection *> * _Nonnull dimensions;
@property (readonly, nonatomic) UniformProjection * _Nonnull projection;

- (_Null_unspecified instancetype)initWithDimensions:(NSArray<MCDimensionalProjection *> * _Nonnull)dimensions;

- (NSUInteger)rank;

- (void)writeToBuffer;

- (void)configure:(MTKView * _Nonnull)view padding:(RectPadding)padding;

- (MCDimensionalProjection * _Nullable)dimensionWithId:(NSInteger)dimensionId;

@end


@interface MetalChart : NSObject<MTKViewDelegate>

@property (copy   , nonatomic) void (^ _Nullable willDraw)(MetalChart * _Nonnull);
@property (copy   , nonatomic) void (^ _Nullable didDraw)(MetalChart * _Nonnull);
@property (assign , nonatomic) RectPadding padding;

- (_Null_unspecified instancetype)init;

- (void)addSeries:(id<MCRenderable> _Nonnull)series
	   projection:(MCSpatialProjection * _Nonnull)projection
;

- (void)removeSeries:(id<MCRenderable> _Nonnull)series;

- (void)addPreRenderable:(id<MCPreRenderable> _Nonnull)object;
- (void)removePreRenderable:(id<MCPreRenderable> _Nonnull)object;

- (void)addPostRenderable:(id<MCPostRenderable> _Nonnull)object;
- (void)removePostRenderable:(id<MCPostRenderable> _Nonnull)object;

- (NSArray<id<MCRenderable>> * _Nonnull)series;

- (NSArray<MCSpatialProjection *> * _Nonnull)projections;

- (void)addToPanRecognizer:(UIPanGestureRecognizer * _Nonnull)recognizer;
- (void)removeFromPanRecognizer:(UIPanGestureRecognizer * _Nonnull)recognizer;

- (void)addToPinchRecognizer:(UIPinchGestureRecognizer * _Nonnull)recognizer;
- (void)removeFromPinchRecognizer:(UIPinchGestureRecognizer * _Nonnull)recognizer;

@end
