//
//  MCAxis.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/11.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MetalChart.h"

@class Engine;
@class UniformLineAttributes;
@class Axis;
@class UniformAxisConfiguration;
@class MCAxis;

typedef void (^MCAxisConfiguratorBlock)(UniformAxisConfiguration *_Nonnull axis,
										MCDimensionalProjection *_Nonnull dimension,
										MCDimensionalProjection *_Nonnull orthogonal);

@protocol MCAxisConfigurator<NSObject>

- (void)configureUniform:(UniformAxisConfiguration * _Nonnull)uniform
		   withDimension:(MCDimensionalProjection * _Nonnull)dimension
			  orthogonal:(MCDimensionalProjection * _Nonnull)orthogonal
;

@end


@protocol MCAxisDecoration<NSObject>

- (void)encodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
			  axis:(MCAxis * _Nonnull)axis
		projection:(UniformProjection * _Nonnull)projection
;

@end


@interface MCAxis : NSObject<MCAttachment>

@property (readonly, nonatomic) MCSpatialProjection *		_Nonnull  projection;
@property (readonly, nonatomic) MCDimensionalProjection *	_Nonnull  dimension;

@property (readonly, nonatomic) Axis *						_Nonnull  axis;
@property (readonly, nonatomic) id<MCAxisConfigurator>		_Nonnull  conf;
@property (strong  , nonatomic) id<MCAxisDecoration>		_Nullable decoration;

- (_Nonnull instancetype)initWithEngine:(Engine * _Nonnull)engine
							 Projection:(MCSpatialProjection * _Nonnull)projection
							  dimension:(NSInteger)dimensionId
						  configuration:(id<MCAxisConfigurator> _Nonnull)conf
;

- (void)setMinorTickCountPerMajor:(NSUInteger)count;

@end



@interface MCBlockAxisConfigurator : NSObject<MCAxisConfigurator>

- (instancetype _Nonnull)initWithBlock:(MCAxisConfiguratorBlock _Nonnull)block; 

@end


