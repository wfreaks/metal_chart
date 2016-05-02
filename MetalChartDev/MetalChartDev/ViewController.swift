//
//  ViewController.swift
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/03.
//  Copyright © 2015年 freaks. All rights reserved.
//

import UIKit
import Metal
import FMChartSupport
import HealthKit

class ViewController: UIViewController {

	@IBOutlet var metalView: MetalView!
	@IBOutlet var panRecognizer: FMPanGestureRecognizer!
	@IBOutlet var pinchRecognizer: UIPinchGestureRecognizer!
	@IBOutlet var tapRecognizer: UITapGestureRecognizer!
	
	var chart : MetalChart = MetalChart()
	var chartConf : FMChartConfigurator? = nil
	let resource : FMDeviceResource = FMDeviceResource.defaultResource()!
	let store : HKHealthStore = HKHealthStore()
	var refDate : NSDate? = nil
	
	let seriesCapacity : UInt = 4
	var stepSeries : FMOrderedAttributedSeries? = nil
	var weightSeries : FMOrderedAttributedSeries? = nil
	var systolicSeries : FMOrderedSeries? = nil
	var diastolicSeries : FMOrderedSeries? = nil
	
	var dateUpdater : FMProjectionUpdater? = nil;
	var stepUpdater : FMProjectionUpdater? = nil;
	var weightUpdater : FMProjectionUpdater? = nil;
	var pressureUpdater : FMProjectionUpdater? = nil;
	
	var weightLabel : FMAxisLabel? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
		metalView.device = resource.device
		let v : Double = 0.9
		let alpha : Double = 1
		metalView.clearColor = MTLClearColorMake(v,v,v,alpha)
		metalView.addGestureRecognizer(tapRecognizer)
		
		setupChart()
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		loadData()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func setupChart() {
		let engine = FMEngine(resource: resource, surface: FMSurfaceConfiguration.defaultConfiguration())
		let fps = 0;
		let configurator : FMChartConfigurator = FMChartConfigurator(chart:chart, engine:engine, view:metalView, preferredFps: fps)
		chartConf = configurator
		let padding = RectPadding(left: 45, top: 30, right: 35, bottom: 30)
		chart.padding = padding
		
		configurator.bindGestureRecognizersPan(panRecognizer, pinch: pinchRecognizer)
		configurator.addPlotAreaWithColor(UIColor.whiteColor()).attributes.setAllCornerRadius(5)
		
		stepSeries = configurator.createAttributedSeries(seriesCapacity)
		weightSeries = configurator.createAttributedSeries(seriesCapacity)
		systolicSeries = configurator.createSeries(seriesCapacity)
		diastolicSeries = configurator.createSeries(seriesCapacity)
		
		let dateDim = 1
		let stepDim = 2
		let weightDim = 3
		let pressureDim = 4
		
		dateUpdater = FMProjectionUpdater()
		let daySec : CGFloat = 24 * 60 * 60
		let dateLength = 7 * daySec;
		dateUpdater?.addFilterToLast(FMSourceFilter(minValue: -5 * daySec, maxValue: 0, expandMin: true, expandMax: true))
		dateUpdater?.addFilterToLast(FMPaddingFilter(paddingLow: daySec, high: daySec, shrinkMin: false, shrinkMax: false, applyToCurrent:true))
		// 物理サイズで320px - paddingで見える分とする.
		let dateScale : CGFloat = dateLength / (320 - 80)
		let dateWindowLength = FMScaledWindowLength(minScale: dateScale * 0.5, maxScale: dateScale, defaultScale: dateScale)
		let dateWindowPos = FMAnchoredWindowPosition(anchor: 0.5, defaultValue: 0, windowLength: dateWindowLength)
		configurator.addWindowFilterToUpdater(dateUpdater!, length: dateWindowLength, position: dateWindowPos, orientation: FMDimOrientation.Horizontal)
		
		stepUpdater = FMProjectionUpdater()
		stepUpdater?.addFilterToLast(FMSourceFilter(minValue: 0, maxValue: 2000, expandMin: true, expandMax: true))
		stepUpdater?.addFilterToLast(FMIntervalFilter(anchor: 0, interval: 1000, shrinkMin: false, shrinkMax: false))
		
		weightUpdater = FMProjectionUpdater()
		weightUpdater?.addFilterToLast(FMSourceFilter(minValue: 50, maxValue: 60, expandMin: false, expandMax: false))
		weightUpdater?.addFilterToLast(FMIntervalFilter(anchor: 0, interval: 5.001, shrinkMin: false, shrinkMax: false))
		
		pressureUpdater = FMProjectionUpdater()
		pressureUpdater?.addFilterToLast(FMSourceFilter(minValue: 60, maxValue: 120, expandMin: false, expandMax: false))
		pressureUpdater?.addFilterToLast(FMIntervalFilter(anchor: 0, interval: 5, shrinkMin: false, shrinkMax: false))
 		
		let stepSpace : FMProjectionCartesian2D = configurator.spaceWithDimensionIds([dateDim,stepDim]) { (dimId) -> FMProjectionUpdater? in
			if(dimId == dateDim) {
				return self.dateUpdater
			}
			return self.stepUpdater
		}
		
		let weightSpace : FMProjectionCartesian2D = configurator.spaceWithDimensionIds([dateDim, weightDim]) { (dimId) -> FMProjectionUpdater? in
			return self.weightUpdater
		}
		
		let pressureSpace : FMProjectionCartesian2D = configurator.spaceWithDimensionIds([dateDim, pressureDim]) { (dimId) -> FMProjectionUpdater? in
			return self.pressureUpdater
		}
		
		let stepBar = configurator.addAttributedBarToSpace(stepSpace, series: stepSeries!, attributesCapacity: 3)
//		let weightLine = configurator.addAttributedLineToSpace(weightSpace, series: weightSeries!, attributesCapacity: 2)
//		let weightPoint = configurator.addAttributedPointToSpace(weightSpace, series: weightSeries!, attributesCapacity: 2)
//		let systolicLine = configurator.addLineToSpace(pressureSpace, series: systolicSeries!)
//		let diastolicLine = configurator.addLineToSpace(pressureSpace, series: diastolicSeries!)
//		let systolicPoint = configurator.setPointToLine(systolicLine)
//		let diastolicPoint = configurator.setPointToLine(diastolicLine)
		
		let weightColor : vector_float4 = UIColor(red: 0.4, green: 0.7, blue: 0.9, alpha: 1.0).vector()
		let systolicColor = UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0).vector()
		let diastolicColor = UIColor(red: 0.9, green: 0.4, blue: 0.2, alpha: 1.0).vector()
		let stepColor = UIColor(white: 0.5, alpha: 1.0).vector()
		
		stepBar.attributesArray[0].setBarWidth(20)
		stepBar.attributesArray[0].setCornerRadius(5, rt: 5, lb: 0, rb: 0)
		stepBar.attributesArray[0].setColor(UIColor(white: 0.7, alpha: 1))
		stepBar.attributesArray[1].setBarWidth(20)
		stepBar.attributesArray[1].setCornerRadius(5, rt: 5, lb: 0, rb: 0)
		stepBar.attributesArray[1].setColor(UIColor(white: 0.5, alpha: 1))
		stepBar.attributesArray[2].setBarWidth(20)
		stepBar.attributesArray[2].setCornerRadius(5, rt: 5, lb: 0, rb: 0)
		stepBar.attributesArray[2].setColor(UIColor(white: 0.3, alpha: 1))
//		weightLine.attributesArray[0].setWidth(8)
//		weightLine.attributesArray[0].setColorVec(weightColor)
//		weightLine.attributesArray[1].setWidth(6)
//		weightLine.attributesArray[1].setColor(UIColor.blueColor())
//		weightLine.attributesArray[1].setDashLineLength(0.001)
//		weightLine.attributesArray[1].setDashSpaceLength(1)
//		weightLine.attributesArray[1].setDashRepeatAnchor(1)
//		weightLine.attributesArray[1].setDashLineAnchor(0)
//		
//		weightLine.conf.setAlpha(0.6)
//		weightLine.conf.enableOverlay = true
//		
//		configurePointAttributes(weightPoint.attributesArray[0] as! FMUniformPointAttributes, innerRadius: 8, outerColor: weightColor)
//		configurePointAttributes(weightPoint.attributesArray[1] as! FMUniformPointAttributes, innerRadius: 8, outerColor: weightColor)
//		
//		systolicLine.conf.enableOverlay = true
//		systolicLine.attributes.setColorVec(systolicColor)
//		configurePointAttributes(systolicPoint, innerRadius: 6, outerColor: systolicColor)
//		diastolicLine.conf.enableOverlay = true
//		diastolicLine.attributes.setColorVec(diastolicColor)
//		configurePointAttributes(diastolicPoint, innerRadius: 6, outerColor: diastolicColor)
		
		let weightConf = FMBlockAxisConfigurator(relativePosition: 0, tickAnchor: 0, minorTicksFreq: 0, maxTickCount: 5, intervalOfInterval: 1)
		let weightSize = CGSizeMake(45, 25)
		let weightAttributes = [NSForegroundColorAttributeName : UIColor(vector:weightColor)]
		let stepAttributes = [NSForegroundColorAttributeName : UIColor(vector:stepColor)]
		let stepProjection = configurator.dimensionWithId(stepDim)!
		let weightProjection = configurator.dimensionWithId(weightDim)!
		let weightAxis = configurator.addAxisToDimensionWithId(weightDim, belowSeries: false, configurator: weightConf, labelFrameSize: weightSize, labelBufferCount: 12) {
			(val, index, lastIndex, projection) -> [NSMutableAttributedString] in
			let strWeight = String(format: "%.0fkg", Float(val))
			let strStep = String(format: "%.0f歩", Float(weightProjection.convertValue(val, to: stepProjection)))
			return [NSMutableAttributedString(string: strWeight, attributes: weightAttributes), NSMutableAttributedString(string: strStep, attributes: stepAttributes)]
		}
		weightAxis!.axis.axisAttributes.setColorVec(weightColor)
		weightAxis!.axis.majorTickAttributes.setColorVec(weightColor)
		weightAxis!.axis.majorTickAttributes.setLengthModifierStart(0, end: 1)
		let weightLabel = configurator.axisLabelsToAxis(weightAxis!)!.first!
		weightLabel.setFont(UIFont.systemFontOfSize(9, weight: UIFontWeightMedium))
		weightLabel.setFrameAnchorPoint(CGPointMake(1, 0.5))
		weightLabel.setFrameOffset(CGPointMake(-5, 0))
		weightLabel.textAlignment = CGPointMake(1, 0.5)
		self.weightLabel = weightLabel
		
		let pressureConf = FMBlockAxisConfigurator(relativePosition: 1, tickAnchor: 0, minorTicksFreq: 0, maxTickCount: 5, intervalOfInterval: 5)
		let pressureSize = CGSizeMake(30, 25)
		let pressureAttributes = [NSForegroundColorAttributeName : UIColor(vector:systolicColor)]
		let str2 = NSMutableAttributedString(string: "mg/dL", attributes: pressureAttributes)
		let pressureAxis = configurator.addAxisToDimensionWithId(pressureDim, belowSeries: false, configurator: pressureConf, labelFrameSize: pressureSize, labelBufferCount: 12) {
			(val, index, lastIndex, projection) -> [NSMutableAttributedString] in
			let str1 = String(format: "%.0f", Float(val))
			return [NSMutableAttributedString(string: str1, attributes: pressureAttributes), str2]
		}
		pressureAxis!.axis.axisAttributes.setColorVec(systolicColor)
		pressureAxis!.axis.majorTickAttributes.setColorVec(systolicColor)
		let pressureLabel = configurator.axisLabelsToAxis(pressureAxis!)!.first!
		pressureLabel.setFont(UIFont.systemFontOfSize(9, weight: UIFontWeightMedium))
		pressureLabel.setFrameAnchorPoint(CGPointMake(0, 0.5))
		pressureLabel.setFrameOffset(CGPointMake(5, 0))
		pressureLabel.textAlignment = CGPointMake(0, 0.5)
		
		let dateConf = FMBlockAxisConfigurator(relativePosition: 0, tickAnchor: 0, fixedInterval: daySec, minorTicksFreq: 0)
		let dateSize = CGSizeMake(30, 15)
		let dateFmt = NSDateFormatter()
		dateFmt.dateFormat = "M/d"
		let dateAxis = configurator.addAxisToDimensionWithId(dateDim, belowSeries:false, configurator:dateConf, labelFrameSize: dateSize, labelBufferCount: 24) {
			(val, index, lastIndex, projection) -> [NSMutableAttributedString] in
			let date = NSDate(timeInterval: NSTimeInterval(val), sinceDate: self.refDate!)
			let str = dateFmt.stringFromDate(date)
			return [NSMutableAttributedString(string: str)]
		}
		let dateLabel = configurator.axisLabelsToAxis(dateAxis!)!.first!
		dateLabel.setFont(UIFont.systemFontOfSize(9, weight: UIFontWeightThin))
		dateLabel.setFrameOffset(CGPointMake(0, 5))
		
	}
	
	func loadData() {
		stepSeries?.info.clear()
		weightSeries?.info.clear()
		systolicSeries?.info.clear()
		diastolicSeries?.info.clear()
		
		dateUpdater?.clearSourceValues(false)
		stepUpdater?.clearSourceValues(false)
		weightUpdater?.clearSourceValues(false)
		pressureUpdater?.clearSourceValues(false)
		
		let refDate : NSDate = getStartOfDate(NSDate())
		self.refDate = refDate
		let interval : NSDateComponents = NSDateComponents()
		interval.day = 1
		let step = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!
		let weight = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!
		let systolic = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureSystolic)!
		let diastolic = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureDiastolic)!
		
		let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
		
		let stepQuery = HKStatisticsCollectionQuery(quantityType: step, quantitySamplePredicate: nil, options: HKStatisticsOptions.CumulativeSum, anchorDate: refDate, intervalComponents: interval)
		stepQuery.initialResultsHandler = { query, results, error in
			if let collection = results {
				self.stepSeries?.reserve(UInt(collection.statistics().count))
				for statistic in collection.statistics() {
					if let quantity = statistic.sumQuantity() {
						let yValue = CGFloat(quantity.doubleValueForUnit(HKUnit.countUnit()))
						let xValue = CGFloat(statistic.startDate.timeIntervalSinceDate(refDate))
						let attr : UInt = (yValue < 5000) ? (0) : ((yValue < 10000) ? 1 : 2)
						self.stepSeries?.addPoint(CGPointMake(xValue, yValue), attrIndex: attr)
						self.stepUpdater?.addSourceValue(yValue, update: false)
						self.dateUpdater?.addSourceValue(xValue, update: false)
					}
				}
				self.stepUpdater?.updateTarget()
				self.weightLabel?.clearCache()
				self.dateUpdater?.updateTarget()
				self.metalView.setNeedsDisplay()
			}
		}
		
		let kg = HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Kilo)
		let weightQuery = HKSampleQuery(sampleType:weight, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { (query, samples, error) -> Void in
			if let array = samples {
				self.weightSeries?.reserve(UInt(array.count))
				var idx : UInt = 0;
				for sample in (array as! [HKQuantitySample]) {
					let x = CGFloat(sample.startDate.timeIntervalSinceDate(refDate))
					let val = CGFloat(sample.quantity.doubleValueForUnit(kg))
					self.weightSeries?.addPoint(CGPointMake(x, val), attrIndex: idx%2)
					self.weightUpdater?.addSourceValue(val, update: false)
					self.dateUpdater?.addSourceValue(x, update: false)
					idx += 1
				}
				self.weightUpdater?.updateTarget()
				self.weightLabel?.clearCache()
				self.dateUpdater?.updateTarget()
				self.metalView.setNeedsDisplay()
			}
		}
		let mmHg = HKUnit.millimeterOfMercuryUnit()
		let systolicQuery = HKSampleQuery(sampleType:systolic, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { (query, samples, error) -> Void in
			if let array = samples {
				self.systolicSeries?.reserve(UInt(array.count))
				for sample in (array as! [HKQuantitySample]) {
					let x = CGFloat(sample.startDate.timeIntervalSinceDate(refDate))
					let val = CGFloat(sample.quantity.doubleValueForUnit(mmHg))
					self.systolicSeries?.addPoint(CGPointMake(x, val))
					self.pressureUpdater?.addSourceValue(val, update: false)
					self.dateUpdater?.addSourceValue(x, update: false)
				}
				self.pressureUpdater?.updateTarget()
				self.dateUpdater?.updateTarget()
				self.metalView.setNeedsDisplay()
			}
		}
		let diastolicQuery = HKSampleQuery(sampleType:diastolic, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { (query, samples, error) -> Void in
			if let array = samples {
				self.diastolicSeries?.reserve(UInt(array.count))
				for sample in (array as! [HKQuantitySample]) {
					let x = CGFloat(sample.startDate.timeIntervalSinceDate(refDate))
					let val = CGFloat(sample.quantity.doubleValueForUnit(mmHg))
					self.diastolicSeries?.addPoint(CGPointMake(x, val))
					self.pressureUpdater?.addSourceValue(val, update: false)
					self.dateUpdater?.addSourceValue(x, update: false)
				}
				self.pressureUpdater?.updateTarget()
				self.dateUpdater?.updateTarget()
				self.metalView.setNeedsDisplay()
			}
		}
		store.executeQuery(stepQuery)
		store.executeQuery(weightQuery)
		store.executeQuery(systolicQuery)
		store.executeQuery(diastolicQuery)
	}
	
	let calendar : NSCalendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
	func getStartOfDate(date : NSDate) -> NSDate {
		let comp : NSDateComponents = calendar.components([.Year, .Month, .Day], fromDate: date)
		return calendar.dateFromComponents(comp)!
	}
	
	func configurePointAttributes(attrs : FMUniformPointAttributes, innerRadius : Float, outerColor : vector_float4) {
		attrs.setInnerRadius(innerRadius)
		attrs.setOuterRadius(innerRadius * 1.5)
		attrs.setInnerColor(UIColor.whiteColor())
		attrs.setOuterColorVec(outerColor)
	}
	
	@IBAction func chartTapped(sender: UITapGestureRecognizer) {
	}
	
	override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
		coordinator.animateAlongsideTransition(
			{ (context) in
				self.dateUpdater?.updateTarget()
				self.metalView.setNeedsDisplay()
			}, completion: nil)
	}
	
}
