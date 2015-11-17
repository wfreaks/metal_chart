//
//  DevController.m
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/11/16.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "DevController.h"
#import <FMChartSupport/FMChartSupport.h>

@interface DevController()

@property (weak, nonatomic) IBOutlet MetalView *metalView;
@property (nonatomic, readonly) MetalChart *chart;
@property (nonatomic, readonly) FMEngine *engine;
@property (nonatomic, readonly) FMConfigurator *configurator;

@end
@implementation DevController

- (void)viewDidLoad
{
	const double v = 0.9;
	const NSInteger fps = 60;
	
	self.metalView.sampleCount = 2;
	self.metalView.clearColor = MTLClearColorMake(v, v, v, 1);
	_chart = [[MetalChart alloc] init];
	_engine = [[FMEngine alloc] initWithResource:[FMDeviceResource defaultResource]];
	_configurator = [[FMConfigurator alloc] initWithChart:self.chart engine:self.engine view:self.metalView preferredFps:fps];
	
	[self configureChart];
}

- (void)configureChart
{
	FMProjectionPolar *space = [[FMProjectionPolar alloc] initWithResource:self.engine.resource];
	[self.chart addProjection:space];
	
	FMEngine *engine = self.engine;
	
	auto colors = std::make_shared<MTLObjectBuffer<vector_float4>>(engine.resource.device, 3);
	auto values = std::make_shared<MTLObjectBuffer<float>>(engine.resource.device, 3);
	auto total = std::make_shared<MTLObjectBuffer<float>>(engine.resource.device);
	auto count = std::make_shared<MTLObjectBuffer<uint32_t>>(engine.resource.device);
	
	(*colors)[0] = vector4(1.0f, 0.0f, 0.0f, 1.0f);
	(*colors)[1] = vector4(0.0f, 1.0f, 0.0f, 1.0f);
	(*colors)[2] = vector4(0.0f, 0.0f, 1.0f, 1.0f);
	(*values)[0] = 1;
	(*values)[1] = 2;
	(*values)[2] = 3;
	(*total)[0] = 6;
	(*count)[0] = 3;

	[self.configurator addBlockRenderable:^(id<MTLRenderCommandEncoder>  _Nonnull encoder, MetalChart * _Nonnull chart) {
		[encoder pushDebugGroup:@"circle"];
		id<MTLRenderPipelineState> renderState = [engine pipelineStateWithPolar:space.projection
																	   vertFunc:@"PieVertex"
																	   fragFunc:@"PieFragment"
																	 writeDepth:NO];
		[encoder setRenderPipelineState:renderState];
		
		[encoder setVertexBuffer:space.projection.buffer offset:0 atIndex:0];
		[encoder setFragmentBuffer:space.projection.buffer offset:0 atIndex:0];
		[encoder setFragmentBuffer:values->getBuffer() offset:0 atIndex:1];
		[encoder setFragmentBuffer:colors->getBuffer() offset:0 atIndex:2];
		[encoder setFragmentBuffer:total->getBuffer() offset:0 atIndex:3];
		[encoder setFragmentBuffer:count->getBuffer() offset:0 atIndex:4];
		
		[encoder drawPrimitives:MTLPrimitiveTypePoint vertexStart:0 vertexCount:1];
		
		[encoder popDebugGroup];
	}];
}

@end
