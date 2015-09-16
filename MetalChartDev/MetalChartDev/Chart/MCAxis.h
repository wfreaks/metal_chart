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
@class UniformAxis;

typedef void (^MCAxisConfiguratorBlock)(UniformAxis *_Nonnull axis,
										MCDimensionalProjection *_Nonnull dimension,
										MCDimensionalProjection *_Nonnull orthogonal);

@protocol MCAxisConfigurator<NSObject>

- (void)configureUniform:(UniformAxis * _Nonnull)uniform
		   withDimension:(MCDimensionalProjection * _Nonnull)dimension
			  orthogonal:(MCDimensionalProjection * _Nonnull)orthogonal
;

@end



@interface MCAxis : NSObject<MCAttachment>

@property (readonly, nonatomic) MCSpatialProjection *		_Nonnull  projection;
@property (readonly, nonatomic) MCDimensionalProjection *	_Nonnull  dimension;

@property (readonly, nonatomic) Axis *						_Nonnull  axis;
@property (readonly, nonatomic) id<MCAxisConfigurator>		_Nonnull  conf;

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


