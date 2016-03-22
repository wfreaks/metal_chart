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
    [super viewDidLoad];
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
	FMProjectionCartesian2D *space = [self.configurator spaceWithDimensionIds:@[@1, @2] configureBlock:^FMProjectionUpdater * _Nullable(NSInteger dimensionID) {
        return nil;
    }];
	[self.chart addProjection:space];
	
    FMOrderedSeries *series = [self.configurator createSeries:8];
    FMLineSeries *line = [self.configurator addLineToSpace:space series:series];
    
    [line.attributes setWidth:5];
    [line.attributes setEnableOverlay:NO];
    
    [series addPoint:CGPointMake(0, 0)];
    [series addPoint:CGPointMake(0, 0.1000)];
    [series addPoint:CGPointMake(0, 0.1001)];
    [series addPoint:CGPointMake(0.01, 0.2000)];
    
}

@end
