//
//  Circles.m
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/11/18.
//  Copyright © 2015年 freaks. All rights reserved.
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




@implementation FMContinuosArcPrimitive

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
		projection:(FMUniformProjectionPolar *)projection
			values:(FMIndexedFloatBuffer *)values
			offset:(NSUInteger)offset
			 count:(NSUInteger)count
{
	if(count > 0) {
		id<MTLRenderPipelineState> state = [self.engine pipelineStateWithPolar:projection vertFunc:@"ArcContinuosVertex" fragFunc:@"ArcFragment" writeDepth:NO];
		[encoder pushDebugGroup:@"ContinuousArc"];
		
		[encoder setRenderPipelineState:state];
		
		[encoder setVertexBuffer:values.buffer offset:0 atIndex:0];
		[encoder setVertexBuffer:self.configuration.buffer offset:0 atIndex:1];
		[encoder setVertexBuffer:self.attributes.buffer offset:0 atIndex:2];
		[encoder setVertexBuffer:projection.buffer offset:0 atIndex:3];
		
		[encoder setFragmentBuffer:projection.buffer offset:0 atIndex:0];
		
		const NSUInteger vOffset = 12 * offset;
		const NSUInteger vCount = 12 * (count - 1);
		[encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:vOffset vertexCount:vCount];
		
		[encoder popDebugGroup];
	}
}

@end
