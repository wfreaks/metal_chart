//
//  Circles.m
//  FMChart
//
//  Created by Keisuke Mori on 2015/11/18.
//  Copyright © 2015 Keisuke Mori. All rights reserved.
//

#import "Circles.h"
#import "Buffers.h"
#import "CircleBuffers.h"
#import "DeviceResource.h"
#import "Engine.h"

@implementation FMArcPrimitive

- (instancetype)initWithEngine:(FMEngine *)engine
				 configuration:(FMUniformArcConfiguration *)conf
					attributes:(FMUniformArcAttributesArray *)attr
			attributesCapacity:(NSUInteger)capacity
{
	self = [super init];
	if(self) {
		_engine = engine;
		_configuration = (conf) ? conf : [[FMUniformArcConfiguration alloc] initWithResource:engine.resource];
		_attributes = (attr) ? attr : [[FMUniformArcAttributesArray alloc] initWithResource:engine.resource
																				   capacity:capacity];
		[_configuration setRadianScale:-1];
		[_configuration setRadianOffset:M_PI_2];
	}
	return self;
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
		projection:(FMUniformProjectionPolar *)projection
			values:(FMIndexedFloatBuffer *)values
			offset:(NSUInteger)offset
			 count:(NSUInteger)count
{
	abort();
}

@end


@interface FMContinuosArcPrimitive()

@property (nonatomic, readonly) id<MTLRenderPipelineState> pipeline;

@end
@implementation FMContinuosArcPrimitive

- (instancetype)initWithEngine:(FMEngine *)engine
				 configuration:(FMUniformArcConfiguration *)conf
					attributes:(FMUniformArcAttributesArray *)attr
			attributesCapacity:(NSUInteger)capacity
{
	self = [super initWithEngine:engine configuration:conf attributes:attr attributesCapacity:capacity];
	if(self) {
		id<MTLFunction> vertFunc = [engine functionWithName:@"ArcContinuosVertex" library:nil];
		id<MTLFunction> fragFunc = [engine functionWithName:@"ArcFragment" library:nil];
		_pipeline = [engine pipelineStateWithVertFunc:vertFunc fragFunc:fragFunc writeDepth:NO];
	}
	return self;
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
		projection:(FMUniformProjectionPolar *)projection
			values:(FMIndexedFloatBuffer *)values
			offset:(NSUInteger)offset
			 count:(NSUInteger)count
{
	if(count > 0) {
		id<MTLRenderPipelineState> state = _pipeline;
		[encoder pushDebugGroup:NSStringFromClass(self.class)];
		
		[encoder setRenderPipelineState:state];
		
		[encoder setVertexBuffer:values.buffer offset:0 atIndex:0];
		[encoder setVertexBuffer:self.configuration.buffer offset:0 atIndex:1];
		[encoder setVertexBuffer:self.attributes.buffer offset:0 atIndex:2];
		[encoder setVertexBuffer:projection.buffer offset:0 atIndex:3];
		
		[encoder setFragmentBuffer:projection.buffer offset:0 atIndex:0];
		
		const NSUInteger vOffset = 12 * offset;
		const NSUInteger vCount = 12 * count;
		[encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:vOffset vertexCount:vCount];
		
		[encoder popDebugGroup];
	}
}

@end

