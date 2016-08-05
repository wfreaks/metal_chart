//
//  Points.m
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/27.
//  Copyright © 2015 Keisuke Mori. All rights reserved.
//

#import "Points.h"
#import <Metal/Metal.h>
#import "Engine.h"
#import "Buffers.h"
#import "PointBuffers.h"
#import "Series.h"

@interface FMPointPrimitive()

@property (nonatomic, readonly) id<MTLRenderPipelineState> pipeline;

- (instancetype)initWithEngine:(FMEngine*)engine;
- (id<MTLBuffer>)attributesBuffer;
+ (NSString *)vertexFunctionName;
+ (NSString *)fragmentFunctionName;

@end
@implementation FMPointPrimitive

- (instancetype)initWithEngine:(FMEngine *)engine
{
	self = [super init];
	if(self) {
		_engine = engine;
		id<MTLFunction> vertFunc = [engine functionWithName:[self.class vertexFunctionName] library:nil];
		id<MTLFunction> fragFunc = [engine functionWithName:[self.class fragmentFunctionName] library:nil];
		_pipeline = [engine pipelineStateWithVertFunc:vertFunc fragFunc:fragFunc writeDepth:YES];
	}
	return self;
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
		projection:(FMUniformProjectionCartesian2D *)projection
{
	id<FMSeries> const series = self.series;
	if(series) {
		id<MTLRenderPipelineState> renderState = _pipeline;
		id<MTLDepthStencilState> depthState = self.engine.depthState_noDepth;
		[encoder pushDebugGroup:NSStringFromClass(self.class)];
		[encoder setRenderPipelineState:renderState];
		[encoder setDepthStencilState:depthState];
		
		id<MTLBuffer> const vertexBuffer = [series vertexBuffer];
		id<MTLBuffer> const pointBuffer = [self attributesBuffer];
		id<MTLBuffer> const projBuffer = projection.buffer;
		id<MTLBuffer> const infoBuffer = [series info].buffer;
		[encoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];
		[encoder setVertexBuffer:pointBuffer offset:0 atIndex:1];
		[encoder setVertexBuffer:projBuffer offset:0 atIndex:2];
		[encoder setVertexBuffer:infoBuffer offset:0 atIndex:3];
		
		[encoder setFragmentBuffer:pointBuffer offset:0 atIndex:0];
		[encoder setFragmentBuffer:projBuffer offset:0 atIndex:1];
		
		const NSUInteger offset = [self vertexOffsetWithOffset:[series info].offset];
		const NSUInteger count = [self vertexCountWithCount:[series info].count];
		[encoder drawPrimitives:MTLPrimitiveTypePoint vertexStart:offset vertexCount:count];
		
		[encoder popDebugGroup];
	}
}

- (NSUInteger)vertexCountWithCount:(NSUInteger)count { return count; }
- (NSUInteger)vertexOffsetWithOffset:(NSUInteger)offset { return offset; }

+ (NSString *)vertexFunctionName { return nil; }
+ (NSString *)fragmentFunctionName { return nil; }
- (id<FMSeries>)series { return nil; }
- (id<MTLBuffer>)attributesBuffer { return nil; }

@end


@implementation FMOrderedPointPrimitive

- (instancetype)initWithEngine:(FMEngine *)engine
						series:(FMOrderedSeries *)series
					attributes:(FMUniformPointAttributes * _Nullable)attributes
{
	self = [super initWithEngine:engine];
	if(self) {
		FMDeviceResource *res = engine.resource;
		_attributes = (attributes) ? attributes : [[FMUniformPointAttributes alloc] initWithResource:res];
		_series = series;
	}
	return self;
}

+ (NSString *)vertexFunctionName { return @"Point_VertexOrdered"; }
+ (NSString *)fragmentFunctionName { return @"Point_Fragment"; }
- (id<MTLBuffer>)attributesBuffer { return _attributes.buffer; }

@end


@implementation FMOrderedAttributedPointPrimitive

- (instancetype)initWithEngine:(FMEngine *)engine
						series:(FMOrderedAttributedSeries * _Nullable)series
			attributesCapacity:(NSUInteger)capacity
{
	self = [super initWithEngine:engine];
	if(self) {
		_attributesArray = [[FMUniformPointAttributesArray alloc] initWithResource:engine.resource capacity:capacity];
		_series = series;
	}
	return self;
}

+ (NSString *)vertexFunctionName { return @"Point_VertexOrderedAttributed"; }
+ (NSString *)fragmentFunctionName { return @"Point_FragmentAttributed"; }
- (id<MTLBuffer>)attributesBuffer { return _attributesArray.buffer; }

@end


