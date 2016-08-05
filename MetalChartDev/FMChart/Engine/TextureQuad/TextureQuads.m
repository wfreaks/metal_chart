//
//  TextureQuads.m
//  FMChart
//
//  Created by Keisuke Mori on 2015/09/16.
//  Copyright © 2015 Keisuke Mori. All rights reserved.
//

#import "TextureQuads.h"
#import <Metal/Metal.h>
#import "Engine.h"
#import "Buffers.h"
#import "TextureQuad_common.h"
#import "TextureQuadBuffers.h"

@interface FMTextureQuadPrimitive ()

@property (nonatomic, readonly) id<MTLRenderPipelineState> pipeline;

@end
@implementation FMTextureQuadPrimitive

- (instancetype _Nonnull)initWithEngine:(FMEngine *)engine
										 texture:(id<MTLTexture>)texture
{
	self = [super init];
	if(self) {
		FMDeviceResource *resource = engine.resource;
		_engine = engine;
		_dataRegion = [[FMUniformRegion alloc] initWithResource:resource];
		_texRegion = [[FMUniformRegion alloc] initWithResource:resource];
		_texture = texture;
		id<MTLFunction> vertFunc = [engine functionWithName:@"TextureQuad_vertex" library:nil];
		id<MTLFunction> fragFunc = [engine functionWithName:@"TextureQuad_fragment" library:nil];
		_pipeline = [engine pipelineStateWithVertFunc:vertFunc fragFunc:fragFunc writeDepth:NO];
	}
	return self;
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
		projection:(FMUniformProjectionCartesian2D *)projection
			 count:(NSUInteger)count
		dataRegion:(FMUniformRegion *)dataRegion
		 texRegion:(FMUniformRegion *)texRegion
{
	id<MTLTexture> texture = _texture;
	if(texture) {
		id<MTLRenderPipelineState> renderState = _pipeline;
		id<MTLDepthStencilState> depthState = _engine.depthState_noDepth;
		[encoder pushDebugGroup:@"DrawTextureQuad"];
		[encoder setRenderPipelineState:renderState];
		[encoder setDepthStencilState:depthState];
		
		[encoder setVertexBuffer:dataRegion.buffer offset:0 atIndex:0];
		[encoder setVertexBuffer:texRegion.buffer offset:0 atIndex:1];
		[encoder setVertexBuffer:projection.buffer offset:0 atIndex:2];
		
		[encoder setFragmentTexture:_texture atIndex:0];
		
		const NSUInteger vCount = count * 6;
		[encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:vCount];
		
		[encoder popDebugGroup];
	}
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
		projection:(FMUniformProjectionCartesian2D *)projection
			 count:(NSUInteger)count
{
	[self encodeWith:encoder projection:projection count:count dataRegion:_dataRegion texRegion:_texRegion];
}

@end
