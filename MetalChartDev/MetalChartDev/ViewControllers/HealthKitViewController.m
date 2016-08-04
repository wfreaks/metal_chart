//
//  HealthKitViewController.m
//  MetalChartDev
//
//  Created by Keisuke Mori on 2016/08/03.
//  Copyright © 2016年 freaks. All rights reserved.
//

#import "HealthKitViewController.h"

#import <FMChartSupport/FMChartSupport.h>
#import <HealthKit/HealthKit.h>

@interface HealthKitViewController()

@property (nonatomic, weak) IBOutlet FMMetalView *metalView;
@property (nonatomic, weak) IBOutlet FMPanGestureRecognizer *panRec;
@property (nonatomic, weak) IBOutlet UIPinchGestureRecognizer *pinchRec;

@property (nonatomic, readonly) MetalChart *chart;
@property (nonatomic, readonly) FMChartConfigurator *configurator;
@property (nonatomic, readonly) HKHealthStore *store;
@property (nonatomic, readonly) NSDate *refDate;

@property (nonatomic, readonly) FMOrderedAttributedSeries *stepSeries;
@property (nonatomic, readonly) FMOrderedAttributedSeries *weightSeries;
@property (nonatomic, readonly) FMOrderedSeries *systolicSeries;
@property (nonatomic, readonly) FMOrderedSeries *diastolicSeries;

@property (nonatomic, readonly) FMAnchoredWindowPosition *windowPos;
@property (nonatomic, readonly) FMProjectionUpdater *dateUpdater;
@property (nonatomic, readonly) FMProjectionUpdater *stepUpdater;
@property (nonatomic, readonly) FMProjectionUpdater *weightUpdater;
@property (nonatomic, readonly) FMProjectionUpdater *pressureUpdater;

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
	// configure view and chart.
	self.metalView.clearColor = MTLClearColorMake(0.9, 0.9, 0.9, 1);
	_chart = [[MetalChart alloc] init];
	FMEngine *engine = [FMEngine createDefaultEngine];
	_configurator = [[FMChartConfigurator alloc] initWithChart:self.chart
														engine:engine
														  view:self.metalView
												  preferredFps:0];
	self.chart.padding = FMRectPaddingMake(45, 30, 35, 30);
	
	[[self.configurator addPlotAreaWithColor:[UIColor whiteColor]].attributes setAllCornerRadius:5];
	[self.configurator bindGestureRecognizersPan:self.panRec
										   pinch:self.pinchRec];
	
	// create dimensions, space and updaters
	const NSInteger dateDim = 1, stepDim = 2, weightDim = 3, pressureDim = 4;
	
	// 1. date dim updater (scrollable)
	const NSTimeInterval daySec = 24 * 60 * 60;
	
	_dateUpdater = [[FMProjectionUpdater alloc] init];
	[self.dateUpdater addFilterToLast:[[FMSourceFilter alloc] initWithMinValue:-5*daySec
																	  maxValue:0
																	 expandMin:YES
																	 expandMax:YES]];
	[self.dateUpdater addFilterToLast:[[FMPaddingFilter alloc] initWithPaddingLow:daySec
																			 high:daySec
																		shrinkMin:NO
																		shrinkMax:NO
																   applyToCurrent:YES]];
	// 7 days visible on 4 inch devices (320 - padding).
	const CGFloat dateScale = 7*daySec / (320-80);
	FMScaledWindowLength *winLen = [[FMScaledWindowLength alloc] initWithMinScale:dateScale
																		 maxScale:dateScale
																	 defaultScale:dateScale];
	
	FMAnchoredWindowPosition *winPos = [[FMAnchoredWindowPosition alloc] initWithAnchor:0.5
																		   windowLength:winLen
																		defaultPosition:1];
	
	_windowPos = winPos;
	[self.configurator addWindowFilterToUpdater:_dateUpdater
										 length:winLen
									   position:winPos
									orientation:FMDimOrientationHorizontal];
	
	// 2. step dim updater
	_stepUpdater = [[FMProjectionUpdater alloc] init];
	[self.stepUpdater addFilterToLast:[[FMSourceFilter alloc] initWithMinValue:0
																	  maxValue:2000
																	 expandMin:YES
																	 expandMax:YES]];
	[self.stepUpdater addFilterToLast:[[FMPaddingFilter alloc] initWithPaddingLow:0
																			 high:1000
																		shrinkMin:NO
																		shrinkMax:NO
																   applyToCurrent:YES]];
	[self.stepUpdater addFilterToLast:[[FMIntervalFilter alloc] initWithAnchor:0
																	  interval:1000
																	 shrinkMin:NO
																	 shrinkMax:NO]];
	
	// 3. weight dim updater
	_weightUpdater = [[FMProjectionUpdater alloc] init];
	[self.weightUpdater addFilterToLast:[[FMSourceFilter alloc] initWithMinValue:50
																		maxValue:60
																	   expandMin:YES
																	   expandMax:YES]];
	[self.weightUpdater addFilterToLast:[[FMPaddingFilter alloc] initWithPaddingLow:1
																			   high:1
																		  shrinkMin:NO
																		  shrinkMax:NO
																	 applyToCurrent:NO]];
	[self.weightUpdater addFilterToLast:[[FMIntervalFilter alloc] initWithAnchor:0
																		interval:5.0001
																	   shrinkMin:NO
																	   shrinkMax:NO]];
	
	// 4. pressure dim updater
	_pressureUpdater = [[FMProjectionUpdater alloc] init];
	[self.pressureUpdater addFilterToLast:[[FMSourceFilter alloc] initWithMinValue:60
																		  maxValue:120
																		 expandMin:NO
																		 expandMax:NO]];
	[self.pressureUpdater addFilterToLast:[[FMPaddingFilter alloc] initWithPaddingLow:5
																				 high:5
																			shrinkMin:NO
																			shrinkMax:NO
																	   applyToCurrent:NO]];
	[self.pressureUpdater addFilterToLast:[[FMIntervalFilter alloc] initWithAnchor:0
																		  interval:5
																		 shrinkMin:NO
																		 shrinkMax:NO]];
	
	FMProjectionCartesian2D *weightSpace = [self.configurator spaceWithDimensionIds:@[@(dateDim), @(weightDim)]
																	 configureBlock:^FMProjectionUpdater * _Nullable(NSInteger dimensionID)
	{
		if(dimensionID == dateDim) return self.dateUpdater;
		return self.weightUpdater;
	}];
	
	FMProjectionCartesian2D *stepSpace = [self.configurator spaceWithDimensionIds:@[@(dateDim), @(stepDim)]
																   configureBlock:^FMProjectionUpdater * _Nullable(NSInteger dimensionID)
	{
		return self.stepUpdater;
	}];
	
	FMProjectionCartesian2D *pressureSpace = [self.configurator spaceWithDimensionIds:@[@(dateDim), @(pressureDim)]
																	   configureBlock:^FMProjectionUpdater * _Nullable(NSInteger dimensionID)
	{
		return self.pressureUpdater;
	}];
	
	// create data containers and renderers
	_weightSeries = [self.configurator createAttributedSeries:4];
	_stepSeries = [self.configurator createAttributedSeries:4];
	_systolicSeries = [self.configurator createSeries:4];
	_diastolicSeries = [self.configurator createSeries:4];
	
	FMOrderedAttributedPolyLinePrimitive *weightLine = [self.configurator addAttributedLineToSpace:weightSpace
																							series:self.weightSeries
																				attributesCapacity:2];
	
	FMOrderedAttributedPointPrimitive *weightPoint = [self.configurator addAttributedPointToSpace:weightSpace
																						   series:self.weightSeries
																			   attributesCapacity:2];
	
	FMOrderedAttributedBarPrimitive *stepBar = [self.configurator addAttributedBarToSpace:stepSpace
																				   series:self.stepSeries
																	   attributesCapacity:3];
	
	FMOrderedPolyLinePrimitive *systolicLine = [self.configurator addLineToSpace:pressureSpace
																		  series:self.systolicSeries];
	
	FMOrderedPolyLinePrimitive *diastolicLine = [self.configurator addLineToSpace:pressureSpace
																		   series:self.diastolicSeries];
	
	FMOrderedPointPrimitive *systolicPoint = [self.configurator addPointToSpace:pressureSpace
																		 series:self.systolicSeries];
	
	FMOrderedPointPrimitive *diastolicPoint = [self.configurator addPointToSpace:pressureSpace
																		  series:self.diastolicSeries];
	
	// manage visual attributes
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
	
	// add axis and labels
	FMBlockAxisConfigurator *weightConf = [FMBlockAxisConfigurator configuratorWithRelativePosition:0
																						 tickAnchor:0
																					 minorTicksFreq:0
																					   maxTickCount:5
																				 intervalOfInterval:1];
	const CGSize weightSize = CGSizeMake(45, 25);
	NSDictionary *weightAttributes= @{NSForegroundColorAttributeName : [UIColor colorWithVector:weightColor]};
	NSDictionary *stepAttributes = @{NSForegroundColorAttributeName : [UIColor colorWithVector:stepColor]};
	FMDimensionalProjection *stepProjection = [self.configurator dimensionWithId:stepDim];
	FMDimensionalProjection *weightProjection = [self.configurator dimensionWithId:weightDim];
	FMExclusiveAxis *weightAxis = [self.configurator addAxisToDimensionWithId:weightDim
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
	FMExclusiveAxis *pressureAxis = [self.configurator addAxisToDimensionWithId:pressureDim
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
	monthFmt.dateFormat = @"M/d";
	NSDictionary *dayAttrs = @{NSForegroundColorAttributeName : [UIColor grayColor]};
	NSDictionary *monthAttrs = @{NSForegroundColorAttributeName : [UIColor redColor]};
	NSCalendar *cal = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
	__weak typeof(self) weakSelf = self;
	FMExclusiveAxis *dateAxis = [self.configurator addAxisToDimensionWithId:dateDim
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
	
	[self.dateUpdater clearSourceValues:NO];
	[self.stepUpdater clearSourceValues:NO];
	[self.weightUpdater clearSourceValues:NO];
	[self.pressureUpdater clearSourceValues:NO];
	
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
					[self.stepUpdater addSourceValue:yValue update:NO];
					[self.dateUpdater addSourceValue:xValue update:NO];
				}
			}
			[self.stepUpdater updateTarget];
			[self.weightLabel clearCache];
			[self.windowPos reset];
			[self.dateUpdater updateTarget];
			[self.metalView setNeedsDisplay];
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
			NSUInteger idx = 0;
			for (HKQuantitySample *sample in samples) {
				const CGFloat x = [sample.startDate timeIntervalSinceDate:refDate];
				const CGFloat val = [sample.quantity doubleValueForUnit:kg];
				[self.weightSeries addPoint:CGPointMake(x, val) attrIndex:idx%2];
				[self.weightUpdater addSourceValue:val update:NO];
				[self.dateUpdater addSourceValue:x update:NO];
				idx += 1;
			}
			[self.weightUpdater updateTarget];
			[self.weightLabel clearCache];
			[self.windowPos reset];
			[self.dateUpdater updateTarget];
			[self.metalView setNeedsDisplay];
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
				[self.pressureUpdater addSourceValue:val update:NO];
				[self.dateUpdater addSourceValue:x update:NO];
			}
			[self.pressureUpdater updateTarget];
			[self.windowPos reset];
			[self.dateUpdater updateTarget];
			[self.metalView setNeedsDisplay];
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
				[self.pressureUpdater addSourceValue:val update:NO];
				[self.dateUpdater addSourceValue:x update:NO];
			}
			[self.pressureUpdater updateTarget];
			[self.windowPos reset];
			[self.dateUpdater updateTarget];
			[self.metalView setNeedsDisplay];
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
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context)
	{
		[self.dateUpdater updateTarget];
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
