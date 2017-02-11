//
//  TokyoTemperatureViewController.m
//  MetalChartDev
//
//  Created by Keisuke Mori on 2017/01/28.
//  Copyright © 2017年 freaks. All rights reserved.
//

#import "TokyoTemperatureViewController.h"

#import <FMChartSupport/FMChartSupport.h>
#import <FMDB/FMDB.h>

@interface TokyoTemperatureViewController ()

@property (weak, nonatomic) IBOutlet FMMetalView *metalView;
@property (strong, nonatomic) IBOutlet FMPanGestureRecognizer *panRec;
@property (nonatomic) FMDatabase *db;

@property (nonatomic) FMMetalChart *chart;
@property (nonatomic) FMChartConfigurator *conf;

@property (nonatomic) FMOrderedSeries *avgSeries;
@property (nonatomic) FMOrderedSeries *minSeries;
@property (nonatomic) FMOrderedSeries *maxSeries;

@property (nonatomic) FMSpace2D *space;

@end

@implementation TokyoTemperatureViewController

+ (NSString*)fullPathWithPath:(NSString*)path
{
	NSString* dir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
	return [dir stringByAppendingPathComponent:path];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	NSFileManager *m = [NSFileManager defaultManager];
	NSString *destPath = [self.class fullPathWithPath:@"tokyo-temp.sqlite"];
	if(![m fileExistsAtPath:destPath]) {
		NSBundle *bundle = [NSBundle bundleForClass:[TokyoTemperatureViewController class]];
		NSString *resourcePath = [bundle pathForResource:@"tokyo-temperature" ofType:@"sqlite"];
		NSError *err = nil;
		[m copyItemAtPath:resourcePath toPath:destPath error:&err];
		if(err) {
			NSLog(@"error copying sqlite file : %@", err);
		}
	}
	
	FMDatabase *db = [FMDatabase databaseWithPath:destPath];
	if(db && [db open]) {
		self.db = db;
	}
	
	[self configureChart];
	[self loadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)configureChart
{
	self.metalView.clearColor = MTLClearColorMake(.96, .96, .96, 1);
	self.chart = [[FMMetalChart alloc] init];
	self.chart.padding = FMRectPaddingMake(20, 20, 20, 20);
	self.conf = [[FMChartConfigurator alloc] initWithChart:self.chart engine:nil view:self.metalView preferredFps:0];
	
	[self.conf bindGestureRecognizersPan:self.panRec pinch:nil];
	FMPlotArea *area = [self.conf addPlotAreaWithColor:[UIColor colorWithRed:.9 green:.8 blue:.8 alpha:1]];
	[area.attributes setAllCornerRadius:30];
	
	// create date dim (x) with id 1, which represents unix time domain.
	const CGFloat daySec = 60 * 60 * 24;
	FMDimension *dateDim = [self.conf createDimWithId:1 filters:@[[FMPaddingFilter paddingWithLow:daySec high:daySec]]];
	
	const CGFloat dateScale = 120*daySec / 320;
	FMScaledWindowLength *winLen = [[FMScaledWindowLength alloc] initWithMinScale:dateScale
																		 maxScale:dateScale
																	 defaultScale:dateScale];
	
	FMAnchoredWindowPosition *winPos = [[FMAnchoredWindowPosition alloc] initWithAnchor:0.5
																		   windowLength:winLen
																		defaultPosition:1];
	
	[self.conf addWindowToDim:dateDim length:winLen position:winPos horizontal:YES];
	
	// create value dim (y) with id 2, which represents temperatures in celsius degree.
	FMDimension *valDim = [self.conf createDimWithId:2 filters:@[[FMPaddingFilter paddingWithLow:10 high:10]]];
	
	const NSUInteger capacity = 1024 * 8;
	FMSpace2D *space = [self.conf spaceWithDimX:dateDim Y:valDim];
	FMOrderedSeries *avgSeries = [self.conf createSeries:capacity];
//	FMOrderedSeries *minSeries = [self.conf createSeries:capacity];
//	FMOrderedSeries *maxSeries = [self.conf createSeries:capacity];
	
	FMLineSeries<FMOrderedPolyLinePrimitive*> *avgLine = [self.conf addLineToSpace:space series:avgSeries];
	[avgLine.line.attributes setColorRed:.2f green:.9f blue:.2f alpha:1];
	[avgLine.line.attributes setWidth:2];
	[avgLine.line.configuration setEnableOverlay:YES];
//	FMLineSeries<FMOrderedPolyLinePrimitive*> *minLine = [self.conf addLineToSpace:space series:minSeries];
//	[minLine.line.attributes setColorRed:.2f green:.2f blue:.9f alpha:.5f];
//	[minLine.line.attributes setWidth:2];
//	[minLine.line.configuration setEnableOverlay:YES];
//	FMLineSeries<FMOrderedPolyLinePrimitive*> *maxLine = [self.conf addLineToSpace:space series:maxSeries];
//	[maxLine.line.attributes setColorRed:.9f green:.2f blue:.2f alpha:.5f];
//	[maxLine.line.attributes setWidth:2];
//	[maxLine.line.configuration setEnableOverlay:YES];
	
	NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
	fmt.dateFormat = @"yyyy/MM";
	id<FMAxisConfigurator> dateAxisConf = [FMBlockAxisConfigurator configuratorWithRelativePosition:0
																						 tickAnchor:0
																					  fixedInterval:(daySec*365.245)/4
																					 minorTicksFreq:0];
	FMExclusiveAxis *dateAxis = [self.conf addAxisToDimWithId:1
												  belowSeries:NO
												 configurator:dateAxisConf
											   labelFrameSize:CGSizeMake(64, 32)
											 labelBufferCount:16
														label:^NSArray<NSMutableAttributedString *> * _Nonnull(CGFloat value,
																											   NSInteger index,
																											   NSInteger lastIndex,
																											   FMDimensionalProjection * _Nonnull dimension)
								 {
									 return @[[[NSMutableAttributedString alloc] initWithString:[fmt stringFromDate:[NSDate dateWithTimeIntervalSince1970:value+daySec]]]];
								 }];
	FMAxisLabel *dateLabel = [self.conf axisLabelsToAxis:dateAxis].firstObject;
	[dateLabel setFrameAnchorPoint:CGPointMake(.5, 1)];
	[self.conf setRoundRectHookToLabel:dateLabel color:[UIColor colorWithWhite:1 alpha:.7f] radius:2 insets:CGSizeMake(4, 2)];
	
	FMGridLine *dateLine = [self.conf addGridLineToDimensionWithId:1 belowSeries:NO anchor:0 interval:0];
	[dateLine.attributes setWidth:1];
	[dateLine.attributes setColorRed:.5f green:.5f blue:.5f alpha:.5f];
	dateLine.axis = dateAxis;
	
	id<FMAxisConfigurator> valAxisConf = [FMBlockAxisConfigurator configuratorWithRelativePosition:0 tickAnchor:0 fixedInterval:10 minorTicksFreq:0];
	FMExclusiveAxis *valAxis = [self.conf addAxisToDimWithId:2
												 belowSeries:NO
												configurator:valAxisConf
											  labelFrameSize:CGSizeMake(64, 32)
											labelBufferCount:8
													   label:^NSArray<NSMutableAttributedString *> * _Nonnull(CGFloat value,
																											  NSInteger index,
																											  NSInteger lastIndex,
																											  FMDimensionalProjection * _Nonnull dimension)
	{
		return @[[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%.0f°C", value]]];
	}];
	FMAxisLabel *valLabel = [self.conf axisLabelsToAxis:valAxis].firstObject;
	[valLabel setFrameAnchorPoint:CGPointMake(0, .5f)];
	[valLabel setFrameOffset:CGPointMake(5, 0)];
	[valLabel setTextAlignment:CGPointMake(.1, .5)];
	[self.conf setRoundRectHookToLabel:valLabel color:[UIColor colorWithWhite:1 alpha:.7f] radius:2 insets:CGSizeMake(4, 2)];
	
	FMGridLine *valLine = [self.conf addGridLineToDimensionWithId:2 belowSeries:NO anchor:0 interval:0];
	[valLine.attributes setWidth:1];
	[valLine.attributes setColorRed:.5f green:.5f blue:.5f alpha:.5f];
	[valLine.attributes setDashLineLength:5];
	[valLine.attributes setDashSpaceLength:4];
	valLine.axis = valAxis;
	
	// add line area.
	
	FMOrderedPolyLineAreaPrimitive *areaPrimitive = [[FMOrderedPolyLineAreaPrimitive alloc] initWithEngine:self.conf.engine orderedSeries:avgSeries attributes:nil];
	FMLineAreaSeries<FMOrderedPolyLineAreaPrimitive*> *areaSeries = [[FMLineAreaSeries alloc] initWithLineArea:areaPrimitive projection:space.space];
	areaSeries.line = avgLine;
	[self.chart addRenderable:areaSeries];
	
	[areaPrimitive.configuration setAnchorPoint:CGPointMake(0, 10) inDataSpace:YES];
	[areaPrimitive.configuration setColorPositionInDateSpace:YES];
	[areaPrimitive.attributes setGradientStartColor:VectColor(1, 0, 0, .4f)
									  startPosition:CGPointMake(0, 30)
										   endColor:VectColor(1, 0, 0, .1f)
										endPosition:CGPointMake(0, 10)
										 toPositive:YES];
	[areaPrimitive.attributes setGradientStartColor:VectColor(0, 0, 1, .4f)
									  startPosition:CGPointMake(0, -10)
										   endColor:VectColor(0, 0, 1, .1f)
										endPosition:CGPointMake(0, 10)
										 toPositive:NO];
	
	self.avgSeries = avgSeries;
//	self.minSeries = minSeries;
//	self.maxSeries = maxSeries;
	self.space = space;
}

- (void)loadData
{
	{
		FMResultSet *result = [self.db executeQuery:@"select date, value from temperature_avg order by date;"];
		while([result next]) {
			const long unixtime = [result longForColumnIndex:0];
			const CGFloat vx = (CGFloat)unixtime;
			const CGFloat vy = (CGFloat)[result doubleForColumnIndex:1];
			[self.avgSeries addPoint:CGPointMake(vx, vy)];
			[self.space addValueX:vx Y:vy];
		}
		[result close];
	}
//	{
//		FMResultSet *result = [self.db executeQuery:@"select date, value from temperature_min order by date;"];
//		while([result next]) {
//			const long unixtime = [result longForColumnIndex:0];
//			const CGFloat vx = (CGFloat)unixtime;
//			const CGFloat vy = (CGFloat)[result doubleForColumnIndex:1];
//			[self.minSeries addPoint:CGPointMake(vx, vy)];
//			[self.space addValueX:vx Y:vy];
//		}
//		[result close];
//	}
//	{
//		FMResultSet *result = [self.db executeQuery:@"select date, value from temperature_max order by date;"];
//		while([result next]) {
//			const long unixtime = [result longForColumnIndex:0];
//			const CGFloat vx = (CGFloat)unixtime;
//			const CGFloat vy = (CGFloat)[result doubleForColumnIndex:1];
//			[self.maxSeries addPoint:CGPointMake(vx, vy)];
//			[self.space addValueX:vx Y:vy];
//		}
//		[result close];
//	}
	
	[self.space updateRanges];
}

@end



