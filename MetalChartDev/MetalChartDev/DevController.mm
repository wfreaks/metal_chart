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
	
	FMContinuosArcPrimitive *arc = [[FMContinuosArcPrimitive alloc] initWithEngine:engine configuration:nil attributes:nil attributesCapacity:4];
	FMIndexedFloatBuffer *values = [[FMIndexedFloatBuffer alloc] initWithResource:engine.resource capacity:8];
	FMUniformArcAttributesArray *attrs = arc.attributes;
	
	[arc.configuration setInnerRadius:100];
	[arc.configuration setOuterRadius:120];
	
	[values setValue:M_PI_4 index:0 atIndex:1];
	[values setValue:M_PI_2 index:1 atIndex:2];
	[values setValue:3      index:2 atIndex:3];
	[values setValue:2*M_PI index:3 atIndex:4];
	
	[attrs[0] setColor:[[UIColor redColor] vector]];
	[attrs[1] setColor:[[UIColor greenColor] vector]];
	[attrs[2] setColor:[[UIColor blueColor] vector]];
	[attrs[3] setColor:[[UIColor colorWithWhite:1.0 alpha:0.5] vector]];

	[self.configurator addBlockRenderable:^(id<MTLRenderCommandEncoder>  _Nonnull encoder, MetalChart * _Nonnull chart) {
		[arc encodeWith:encoder projection:space.projection values:values offset:0 count:5];
	}];
}

@end
