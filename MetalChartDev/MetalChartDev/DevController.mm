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
	
	FMPieDoughnutSeries *series = [[FMPieDoughnutSeries alloc] initWithEngine:engine
																		  arc:nil
																   projection:space
																	   values:nil
												   attributesCapacityOnCreate:8
													   valuesCapacityOnCreate:16];
	
	FMUniformArcAttributesArray *attrs = series.attrs;
	FMUniformArcConfiguration *conf = series.conf;
	FMPieDoughnutDataProxy *data = series.data;
	
	[conf setRadiusInner:100 outer:120];
	
	[attrs[0] setColor:[[UIColor redColor] vector]];
	[attrs[1] setColor:[[UIColor greenColor] vector]];
	[attrs[2] setColor:[[UIColor blueColor] vector]];
	
	[data addElementWithValue:5 index:0 ID:0];
	[data addElementWithValue:25 index:1 ID:0];
	[data addElementWithValue:125 index:2 ID:0];
	[data sort:NO];
	[data flush];

	[self.chart addSeries:series];
}

@end
