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
	id<MTLDevice> device = engine.resource.device;
	
	const auto values = std::make_shared<MTLObjectBuffer<indexed_value_float>>(device, 16);
	auto& v = *values;
	v[0].value = 0;
	v[1].value = M_PI_4;
	v[2].value = M_PI_2;
	v[3].value = 3;
	v[4].value = 2 * M_PI;
	
	v[1].idx = 0;
	v[2].idx = 1;
	v[3].idx = 0;
	v[4].idx = 1;
	
	const auto conf = std::make_shared<MTLObjectBuffer<uniform_arc_configuration>>(device);
	auto c = *conf;
	c[0].radius_outer = 120;
	c[0].radius_inner = 100;
	
	const auto attrs = std::make_shared<MTLObjectBuffer<uniform_arc_attributes>>(device, 2);
	auto& a = *attrs;
	a[0].color = [[UIColor redColor] vector];
	a[0].radius_inner = 0;
	a[0].radius_outer = 0;
	a[1].color = [[UIColor greenColor] vector];
	a[1].radius_outer = 125;
	a[1].radius_inner = 100;

	[self.configurator addBlockRenderable:^(id<MTLRenderCommandEncoder>  _Nonnull encoder, MetalChart * _Nonnull chart) {
		[encoder pushDebugGroup:@"circle"];
		id<MTLRenderPipelineState> renderState = [engine pipelineStateWithPolar:space.projection
																	   vertFunc:@"ArcContinuosVertex"
																	   fragFunc:@"ArcFragment"
																	 writeDepth:NO];
		[encoder setRenderPipelineState:renderState];
		
		[encoder setVertexBuffer:values->getBuffer() offset:0 atIndex:0];
		[encoder setVertexBuffer:conf->getBuffer() offset:0 atIndex:1];
		[encoder setVertexBuffer:attrs->getBuffer() offset:0 atIndex:2];
		[encoder setVertexBuffer:space.projection.buffer offset:0 atIndex:3];
		
		[encoder setFragmentBuffer:space.projection.buffer offset:0 atIndex:0];
		
		const NSInteger n = 4;
		[encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:12*n];
		
		[encoder popDebugGroup];
	}];
}

@end
