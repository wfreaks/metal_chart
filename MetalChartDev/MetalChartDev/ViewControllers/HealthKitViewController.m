//
//  HealthKitViewController.m
//  MetalChartDev
//
//  Created by Keisuke Mori on 2016/08/03.
//  Copyright © 2016 Keisuke Mori. All rights reserved.
//

#import "HealthKitViewController.h"

#import <FMChartSupport/FMChartSupport.h>
#import <HealthKit/HealthKit.h>

@interface HealthKitViewController()

@property (nonatomic, weak) IBOutlet FMMetalView *metalView;
@property (nonatomic, weak) IBOutlet FMPanGestureRecognizer *panRec;
@property (nonatomic, weak) IBOutlet UIPinchGestureRecognizer *pinchRec;

@property (nonatomic, readonly) FMMetalChart *chart;
@property (nonatomic, readonly) FMChartConfigurator *configurator;
@property (nonatomic, readonly) HKHealthStore *store;
@property (nonatomic, readonly) NSDate *refDate;

@property (nonatomic, readonly) FMOrderedAttributedSeries *stepSeries;
@property (nonatomic, readonly) FMOrderedAttributedSeries *weightSeries;
@property (nonatomic, readonly) FMOrderedSeries *systolicSeries;
@property (nonatomic, readonly) FMOrderedSeries *diastolicSeries;

@property (nonatomic, readonly) FMAnchoredWindowPosition *windowPos;

@property (nonatomic, readonly) FMAxisLabel *weightLabel;

@end
@implementation HealthKitViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	_store = [[HKHealthStore alloc] init];
	[self setupChart];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self loadData];
}

- (void)setupChart
{
	// 1 : configure view and chart.
	self.metalView.clearColor = MTLClearColorMake(0.9, 0.9, 0.9, 1);
	_chart = [[FMMetalChart alloc] init];
	FMEngine *engine = [FMEngine createDefaultEngine];
	_configurator = [[FMChartConfigurator alloc] initWithChart:self.chart
														engine:engine
														  view:self.metalView
												  preferredFps:0];
	FMChartConfigurator *conf = self.configurator;
	self.chart.padding = FMRectPaddingMake(45, 30, 35, 30);
	
	[[conf addPlotAreaWithColor:[UIColor whiteColor]].attributes setAllCornerRadius:5];
	[conf bindGestureRecognizersPan:self.panRec
							  pinch:self.pinchRec];
	
	// 2 : create dimensions, space and updaters
	const NSInteger dDate = 1, dStep = 2, dWeight = 3, dPressure = 4;
	
	const NSTimeInterval daySec = 24 * 60 * 60;
	FMDimension *dateDim = [conf createDimWithId:dDate filters:@[[FMSourceFilter expandWithMin:-6*daySec max:daySec],
																 [FMPaddingFilter paddingWithLow:daySec high:daySec]]];
	
	// 7 days visible on 4 inch devices (320 - padding).
	const CGFloat dateScale = 7*daySec / (320-80);
	FMScaledWindowLength *winLen = [[FMScaledWindowLength alloc] initWithMinScale:dateScale
																		 maxScale:dateScale
																	 defaultScale:dateScale];
	
	FMAnchoredWindowPosition *winPos = [[FMAnchoredWindowPosition alloc] initWithAnchor:0.5
																		   windowLength:winLen
																		defaultPosition:1];
	
	_windowPos = winPos;
	[conf addWindowToDim:dateDim length:winLen position:winPos horizontal:YES];
	
	FMDimension *stepDim = [conf createDimWithId:dStep filters:@[[FMSourceFilter expandWithMin:0 max:3000],
																 [FMPaddingFilter paddingWithLow:0 high:1000],
																 [FMIntervalFilter filterWithAnchor:0 interval:1000]]];
	
	FMDimension *weightDim = [conf createDimWithId:dWeight filters:@[[FMSourceFilter expandWithMin:50 max:60],
																	 [FMPaddingFilter paddingWithLow:1 high:1],
																	 [FMIntervalFilter filterWithAnchor:0 interval:5.0001]]];
	
	FMDimension *pressureDim = [conf createDimWithId:dPressure filters:@[[FMSourceFilter expandWithMin:60 max:120],
																		 [FMPaddingFilter paddingWithLow:5 high:5],
																		 [FMIntervalFilter filterWithAnchor:0 interval:5]]];
	
	FMSpace2D *weightSpace = [conf spaceWithDimX:dateDim Y:weightDim];
	FMSpace2D *stepSpace = [conf spaceWithDimX:dateDim Y:stepDim];
	FMSpace2D *pressureSpace = [conf spaceWithDimX:dateDim Y:pressureDim];
	
	// 3 : create data containers and renderers (their size get extended when loading data)
	_weightSeries = [conf createAttributedSeries:4];
	_stepSeries = [conf createAttributedSeries:4];
	_systolicSeries = [conf createSeries:4];
	_diastolicSeries = [conf createSeries:4];
	
	FMOrderedAttributedPolyLinePrimitive *weightLine = [conf addAttributedLineToSpace:weightSpace
																			   series:self.weightSeries
																   attributesCapacity:2];
	
	FMOrderedAttributedPointPrimitive *weightPoint = [conf addAttributedPointToSpace:weightSpace
																			  series:self.weightSeries
																  attributesCapacity:2];
	
	FMOrderedAttributedBarPrimitive *stepBar = [conf addAttributedBarToSpace:stepSpace
																	  series:self.stepSeries
														  attributesCapacity:3];
	
	FMOrderedPolyLinePrimitive *systolicLine = [conf addLineToSpace:pressureSpace
															 series:self.systolicSeries];
	
	FMOrderedPolyLinePrimitive *diastolicLine = [conf addLineToSpace:pressureSpace
															  series:self.diastolicSeries];
	
	FMOrderedPointPrimitive *systolicPoint = [conf addPointToSpace:pressureSpace
															series:self.systolicSeries];
	
	FMOrderedPointPrimitive *diastolicPoint = [conf addPointToSpace:pressureSpace
															 series:self.diastolicSeries];
	
	// 4 : manage visual attributes
	vector_float4 weightColor = [[UIColor colorWithRed: 0.4 green: 0.7 blue: 0.9 alpha: 1.0] vector];
	vector_float4 systolicColor = [[UIColor colorWithRed: 0.9 green: 0.3 blue: 0.3 alpha: 1.0] vector];
	vector_float4 diastolicColor = [[UIColor colorWithRed: 0.9 green: 0.4 blue: 0.2 alpha: 1.0] vector];
	vector_float4 stepColor = [[UIColor colorWithHue:0.5 saturation:0.5 brightness:0.7 alpha:1.0] vector];
	
	const FMRectCornerRadius corner = FMRectCornerRadiusMake(5, 5, 0, 0);
	stepBar.attributesArray[0].barWidth = 20;
	[stepBar.attributesArray[0] setCornerRadius:corner];
	[stepBar.attributesArray[0] setColor:[UIColor colorWithHue: 0.5 saturation: 0.1 brightness: 0.7 alpha: 1]];
	stepBar.attributesArray[1].barWidth = 20;
	[stepBar.attributesArray[1] setCornerRadius:corner];
	[stepBar.attributesArray[1] setColor:[UIColor colorWithHue: 0.5 saturation: 0.3 brightness: 0.7 alpha: 1]];
	stepBar.attributesArray[0].barWidth = 20;
	[stepBar.attributesArray[0] setCornerRadius:corner];
	[stepBar.attributesArray[0] setColor:[UIColor colorWithHue: 0.5 saturation: 0.7 brightness: 0.7 alpha: 1]];
	[weightLine.attributesArray[0] setWidth:8];
	[weightLine.attributesArray[0] setColorVec:weightColor];
	[weightLine.attributesArray[1] setWidth:6];
	[weightLine.attributesArray[1] setColorVec:weightColor];
	[weightLine.attributesArray[1] setDashLineLength:0.001];
	[weightLine.attributesArray[1] setDashSpaceLength:1];
	[weightLine.attributesArray[1] setDashRepeatAnchor:1];
	[weightLine.attributesArray[1] setDashLineAnchor:0];
	
	[weightLine.conf setAlpha:0.6];
	weightLine.conf.enableOverlay = YES;
	
	[self.class configurePointAttributes:weightPoint.attributesArray[0] innerRadius:8 outerColor:weightColor];
	[self.class configurePointAttributes:weightPoint.attributesArray[1] innerRadius:8 outerColor:weightColor];
	
	systolicLine.conf.enableOverlay = YES;
	[systolicLine.attributes setColorVec:systolicColor];
	[self.class configurePointAttributes:systolicPoint.attributes innerRadius:6 outerColor:systolicColor];
	diastolicLine.conf.enableOverlay = YES;
	[diastolicLine.attributes setColorVec:diastolicColor];
	[self.class configurePointAttributes:diastolicPoint.attributes innerRadius:6 outerColor:diastolicColor];
	
	// 5 : add axis and labels, manage attributes
	FMBlockAxisConfigurator *weightConf = [FMBlockAxisConfigurator configuratorWithRelativePosition:0
																						 tickAnchor:0
																					 minorTicksFreq:0
																					   maxTickCount:5
																				 intervalOfInterval:1];
	const CGSize weightSize = CGSizeMake(45, 25);
	NSDictionary *weightAttributes= @{NSForegroundColorAttributeName : [UIColor colorWithVector:weightColor]};
	NSDictionary *stepAttributes = @{NSForegroundColorAttributeName : [UIColor colorWithVector:stepColor]};
	FMDimensionalProjection *stepProjection = stepDim.dim;
	FMDimensionalProjection *weightProjection = weightDim.dim;
	FMExclusiveAxis *weightAxis = [self.configurator addAxisToDimWithId:dWeight
															belowSeries:NO
																 configurator:weightConf
														 labelFrameSize:weightSize
													   labelBufferCount:8
																  label:^NSArray<NSMutableAttributedString *> * _Nonnull(CGFloat val,
																														 NSInteger index,
																														 NSInteger lastIndex,
																														 FMDimensionalProjection * _Nonnull dimension)
	{
		NSString *strWeight = [NSString stringWithFormat:@"%.0fkg", (float)val];
		NSString *strStep = [NSString stringWithFormat:@"%.0f歩", (float)([weightProjection convertValue:val to:stepProjection])];
		return @[[[NSMutableAttributedString alloc] initWithString:strWeight attributes:weightAttributes],
				 [[NSMutableAttributedString alloc] initWithString:strStep attributes:stepAttributes]];
	}];
	
	[weightAxis.axis.axisAttributes setColorVec:weightColor];
	[weightAxis.axis.majorTickAttributes setColorVec:weightColor];
	[weightAxis.axis.majorTickAttributes setLengthModifierStart:0 end:1];
	FMAxisLabel *weightLabel = [[self.configurator axisLabelsToAxis:weightAxis] firstObject];
	[weightLabel setFont:[UIFont systemFontOfSize:9 weight:UIFontWeightMedium]];
	[weightLabel setFrameAnchorPoint:CGPointMake(1,0.5)];
	[weightLabel setFrameOffset:CGPointMake(-5, 0)];
	weightLabel.textAlignment = CGPointMake(1, 0.5);
	_weightLabel = weightLabel;
	
	FMBlockAxisConfigurator *pressureConf = [FMBlockAxisConfigurator configuratorWithRelativePosition:1
																						   tickAnchor:0
																					   minorTicksFreq:0
																						 maxTickCount:5
																				   intervalOfInterval:5];
	const CGSize pressureSize = CGSizeMake(30, 25);
	NSDictionary* pressureAttributes = @{NSForegroundColorAttributeName : [UIColor colorWithVector:systolicColor]};
	NSMutableAttributedString *str2 = [[NSMutableAttributedString alloc] initWithString:@"mg/dL" attributes: pressureAttributes];
	FMExclusiveAxis *pressureAxis = [self.configurator addAxisToDimWithId:dPressure
															  belowSeries:NO
															 configurator:pressureConf
														   labelFrameSize:pressureSize
														 labelBufferCount:8
																	label:^NSArray<NSMutableAttributedString *> * _Nonnull(CGFloat value,
																														   NSInteger index,
																														   NSInteger lastIndex,
																														   FMDimensionalProjection * _Nonnull dimension)
	{
		NSString *str1 = [NSString stringWithFormat:@"%.0f", (float)(value)];
		return @[[[NSMutableAttributedString alloc] initWithString:str1 attributes:pressureAttributes], str2];
	}];
	[pressureAxis.axis.axisAttributes setColorVec:systolicColor];
	[pressureAxis.axis.majorTickAttributes setColorVec:systolicColor];
	FMAxisLabel *pressureLabel = [[self.configurator axisLabelsToAxis:pressureAxis] firstObject];
	[pressureLabel setFont:[UIFont systemFontOfSize: 9 weight:UIFontWeightMedium]];
	[pressureLabel setFrameAnchorPoint:CGPointMake(0, 0.5)];
	[pressureLabel setFrameOffset:CGPointMake(5, 0)];
	pressureLabel.textAlignment = CGPointMake(0, 0.5);
	
	FMBlockAxisConfigurator *dateConf = [FMBlockAxisConfigurator configuratorWithRelativePosition:0
																					   tickAnchor:0
																					fixedInterval:daySec
																				   minorTicksFreq:0];
	const CGSize dateSize = CGSizeMake(40, 15);
	NSDateFormatter *dateFmt = [[NSDateFormatter alloc] init];
	NSDateFormatter *monthFmt = [[NSDateFormatter alloc] init];
	dateFmt.dateFormat = @"d";
	monthFmt.dateFormat = @"yy/M/d";
	NSDictionary *dayAttrs = @{NSForegroundColorAttributeName : [UIColor grayColor]};
	NSDictionary *monthAttrs = @{NSForegroundColorAttributeName : [UIColor redColor]};
	NSCalendar *cal = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
	__weak typeof(self) weakSelf = self;
	FMExclusiveAxis *dateAxis = [self.configurator addAxisToDimWithId:dDate
														  belowSeries:NO
														 configurator:dateConf
													   labelFrameSize:dateSize
													 labelBufferCount:24
																label:^NSArray<NSMutableAttributedString *> * _Nonnull(CGFloat value,
																													   NSInteger index,
																													   NSInteger lastIndex,
																													   FMDimensionalProjection * _Nonnull dimension)
	{
		NSDate* date = [NSDate dateWithTimeInterval:value sinceDate:weakSelf.refDate];
		const NSInteger day = [cal component:NSCalendarUnitDay fromDate:date];
		const NSInteger maxDay = [cal rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:date].length;
		const BOOL useMonth = (day == 1) || (index == 0 && day != maxDay);
		NSDateFormatter *fmt = (useMonth) ? monthFmt : dateFmt;
		NSDictionary *attrs = (useMonth) ? monthAttrs : dayAttrs;
		NSString *str = [fmt stringFromDate:date];
		return @[[[NSMutableAttributedString alloc] initWithString:str attributes:attrs]];
	}];
	FMAxisLabel *dateLabel = [[self.configurator axisLabelsToAxis:dateAxis] firstObject];
	[dateLabel setFont:[UIFont systemFontOfSize:9 weight:UIFontWeightMedium]];
	[dateLabel setFrameOffset:CGPointMake(0, 5)];
	dateLabel.cacheModifier = ^void(NSInteger oldMin, NSInteger oldMax, NSInteger* newMin, NSInteger* newMax)
	{
		const NSInteger aMin = *newMin;
		if (aMin > oldMin) {
			*newMin = MAX(oldMin+2, aMin+1);
		} else if (aMin < oldMin) {
			*newMin = MAX(oldMin+1, aMin+2);
		}
	};
	UIColor *fillColor = [UIColor colorWithWhite:1 alpha:1];
	id<FMLineDrawHook> hook = [FMBlockLineDrawHook hookWithBlock:^(NSAttributedString * _Nonnull string,
																   CGContextRef  _Nonnull context,
																   const CGRect * _Nonnull drawRect)
	{
		if([string.string containsString:@"/"]) {
			CGContextSetFillColorWithColor(context, fillColor.CGColor);
			const CGRect rect = CGRectInset(*drawRect, -2, -1);
			CGContextAddPath(context, [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:2].CGPath);
			CGContextFillPath(context);
		}
	}];
	[self.configurator addRetainedObject:hook];
	[dateLabel setLineDrawHook:hook];
}

+ (void)configurePointAttributes:(FMUniformPointAttributes*)attrs
					 innerRadius:(float)innerRadius
					  outerColor:(vector_float4)outerColor
{
	[attrs setInnerRadius:innerRadius];
	[attrs setOuterRadius:innerRadius * 1.5];
	[attrs setInnerColor:[UIColor whiteColor]];
	[attrs setOuterColorVec:outerColor];
}


- (void)loadData
{
	[self.stepSeries.info clear];
	[self.weightSeries.info clear];
	[self.systolicSeries.info clear];
	[self.diastolicSeries.info clear];
	
	[self.configurator clearValuesForAllDimensions];
	FMSpace2D *stepSpace = [self.configurator findSpaceWithIdX:1 Y:2];
	FMSpace2D *weightSpace = [self.configurator findSpaceWithIdX:1 Y:3];
	FMSpace2D *pressureSpace = [self.configurator findSpaceWithIdX:1 Y:4];
	
	NSDate *refDate = [self.class startOfDate:[NSDate date]];
	_refDate = refDate;
	NSDateComponents *interval = [[NSDateComponents alloc] init];
	interval.day = 1;
	HKQuantityType *step = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
	HKQuantityType *weight = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
	HKQuantityType *systolic = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodPressureSystolic];
	HKQuantityType *diastolic = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodPressureDiastolic];
	
	NSSortDescriptor* sort = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierEndDate ascending:NO];
	
	HKStatisticsCollectionQuery *stepQuery = [[HKStatisticsCollectionQuery alloc] initWithQuantityType:step
																			   quantitySamplePredicate:nil
																							   options:HKStatisticsOptionCumulativeSum
																							anchorDate:refDate
																					intervalComponents:interval];
	
	stepQuery.initialResultsHandler = ^(HKQuery* query, HKStatisticsCollection* results, NSError *error)
	{
		if(results) {
			[self.stepSeries reserve:(NSUInteger)(results.statistics.count)];
			for(HKStatistics *statistic in results.statistics) {
				HKQuantity *quantity = statistic.sumQuantity;
				if(quantity) {
					const CGFloat yValue = [quantity doubleValueForUnit:[HKUnit countUnit]];
					const CGFloat xValue = [statistic.startDate timeIntervalSinceDate:refDate];
					const NSUInteger attr = (yValue < 5000) ? (0) : ((yValue < 10000) ? 1 : 2);
					[self.stepSeries addPoint:CGPointMake(xValue, yValue) attrIndex:attr];
					[stepSpace addValueX:xValue Y:yValue];
				}
			}
			[self.weightLabel clearCache];
			[self.windowPos reset];
			[stepSpace updateRanges];
		}
	};
	
	HKUnit* kg = [HKUnit gramUnitWithMetricPrefix:HKMetricPrefixKilo];
	HKSampleQuery* weightQuery = [[HKSampleQuery alloc] initWithSampleType:weight
																 predicate:nil
																	 limit:HKObjectQueryNoLimit
														   sortDescriptors:@[sort]
															resultsHandler:^(HKSampleQuery * _Nonnull query,
																			 NSArray<__kindof HKSample *> * _Nullable samples,
																			 NSError * _Nullable error)
	{
		if (samples) {
			[self.weightSeries reserve:samples.count];
			NSCalendar *cal = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
			NSDateComponents *baseDateComp = [[NSDateComponents alloc] init];
			baseDateComp.year = 1970;
			baseDateComp.month = 1;
			baseDateComp.day = 1;
			NSDate *d = [cal dateFromComponents:baseDateComp];
			const NSInteger count = samples.count;
			for (NSInteger i = 0; i < count; ++i) {
				HKQuantitySample *sample = samples[i];
				HKQuantitySample *ns = (count-1 > i) ? samples[i+1] : nil;
				const NSInteger cd = [cal components:NSCalendarUnitDay fromDate:d toDate:sample.startDate options:0].day;
				const NSInteger nd = (ns) ? [cal components:NSCalendarUnitDay fromDate:d toDate:ns.startDate options:0].day : -1;
				const CGFloat x = [sample.startDate timeIntervalSinceDate:refDate];
				const CGFloat val = [sample.quantity doubleValueForUnit:kg];
				const BOOL dashed = (nd >= 0 && abs((int)(cd-nd)) > 1);
				[self.weightSeries addPoint:CGPointMake(x, val) attrIndex:(dashed ? 1 : 0)];
				[weightSpace addValueX:x Y:val];
			}
			[self.weightLabel clearCache];
			[self.windowPos reset];
			[weightSpace updateRanges];
		}
	}];
	HKUnit *mmHg = [HKUnit millimeterOfMercuryUnit];
	HKSampleQuery *systolicQuery = [[HKSampleQuery alloc] initWithSampleType:systolic
																   predicate:nil
																	   limit:HKObjectQueryNoLimit
															 sortDescriptors:@[sort]
															  resultsHandler:^(HKSampleQuery * _Nonnull query,
																			   NSArray<__kindof HKSample *> * _Nullable samples,
																			   NSError * _Nullable error)
	{
		if (samples) {
			[self.systolicSeries reserve:samples.count];
			for(HKQuantitySample *sample in samples) {
				const CGFloat x = [sample.startDate timeIntervalSinceDate:refDate];
				const CGFloat val = [sample.quantity doubleValueForUnit:mmHg];
				[self.systolicSeries addPoint:CGPointMake(x, val)];
				[pressureSpace addValueX:x Y:val];
			}
			[self.windowPos reset];
			[pressureSpace updateRanges];
		}
	}];
	HKSampleQuery *diastolicQuery = [[HKSampleQuery alloc] initWithSampleType:diastolic
																	predicate:nil
																		limit:HKObjectQueryNoLimit
															  sortDescriptors:@[sort]
															   resultsHandler:^(HKSampleQuery * _Nonnull query,
																				NSArray<__kindof HKSample *> * _Nullable samples,
																				NSError * _Nullable error)
	{
		if (samples) {
			[self.diastolicSeries reserve:samples.count];
			for(HKQuantitySample *sample in samples) {
				const CGFloat x = [sample.startDate timeIntervalSinceDate:refDate];
				const CGFloat val = [sample.quantity doubleValueForUnit:mmHg];
				[self.diastolicSeries addPoint:CGPointMake(x, val)];
				[pressureSpace addValueX:x Y:val];
			}
			[self.windowPos reset];
			[pressureSpace updateRanges];
		}
	}];
	
	[self.store executeQuery:stepQuery];
	[self.store executeQuery:weightQuery];
	[self.store executeQuery:systolicQuery];
	[self.store executeQuery:diastolicQuery];
}

- (void)viewWillTransitionToSize:(CGSize)size
	   withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	FMDimension *dateDim = [self.configurator dimWithId:1];
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context)
	{
		[dateDim updateRange];
		[self.metalView setNeedsDisplay];
	} completion:nil];
}

+ (NSDate *)startOfDate:(NSDate *)date
{
	NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
	NSDateComponents *comp = [calendar components:(NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:date];
	return [calendar dateFromComponents:comp];
}

@end
