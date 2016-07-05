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
	let resource : FMDeviceResource = FMDeviceResource.default()!
	let store : HKHealthStore = HKHealthStore()
	var refDate : Date? = nil
	
	let seriesCapacity : UInt = 4
	var stepSeries : FMOrderedAttributedSeries? = nil
	var weightSeries : FMOrderedAttributedSeries? = nil
	var systolicSeries : FMOrderedSeries? = nil
	var diastolicSeries : FMOrderedSeries? = nil
	
	var windowPos : FMAnchoredWindowPosition? = nil;
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
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		loadData()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func setupChart() {
		let engine = FMEngine(resource: resource, surface: FMSurfaceConfiguration.default())
		let fps = 0;
		let configurator : FMChartConfigurator = FMChartConfigurator(chart:chart, engine:engine, view:metalView, preferredFps: fps)
		chartConf = configurator
		let padding = RectPadding(left: 45, top: 30, right: 35, bottom: 30)
		chart.padding = padding
		
		configurator.bindGestureRecognizersPan(panRecognizer, pinch: pinchRecognizer)
		configurator.addPlotArea(with:UIColor.white()).attributes.setAllCornerRadius(5)
		
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
		dateUpdater?.addFilter(toLast:FMSourceFilter(minValue: -5 * daySec, maxValue: 0, expandMin: true, expandMax: true))
		dateUpdater?.addFilter(toLast:FMPaddingFilter(paddingLow: daySec, high: daySec, shrinkMin: false, shrinkMax: false, applyToCurrent:true))
		// 物理サイズで320px - paddingで見える分とする.
		let dateScale : CGFloat = dateLength / (320 - 80)
		let dateWindowLength = FMScaledWindowLength(minScale: dateScale * 0.5, maxScale: dateScale, defaultScale: dateScale)
		let dateWindowPos = FMAnchoredWindowPosition(anchor: 0.5, windowLength: dateWindowLength, defaultPosition: 1)
		configurator.addWindowFilter(to: dateUpdater!, length: dateWindowLength, position: dateWindowPos, orientation: FMDimOrientation.horizontal)
		windowPos = dateWindowPos;
		
		stepUpdater = FMProjectionUpdater()
		stepUpdater?.addFilter(toLast: FMSourceFilter(minValue: 0, maxValue: 2000, expandMin: true, expandMax: true))
		stepUpdater?.addFilter(toLast: FMIntervalFilter(anchor: 0, interval: 1000, shrinkMin: false, shrinkMax: false))
		
		weightUpdater = FMProjectionUpdater()
		weightUpdater?.addFilter(toLast: FMSourceFilter(minValue: 50, maxValue: 60, expandMin: false, expandMax: false))
		weightUpdater?.addFilter(toLast: FMIntervalFilter(anchor: 0, interval: 5.001, shrinkMin: false, shrinkMax: false))
		
		pressureUpdater = FMProjectionUpdater()
		pressureUpdater?.addFilter(toLast: FMSourceFilter(minValue: 60, maxValue: 120, expandMin: false, expandMax: false))
		pressureUpdater?.addFilter(toLast: FMIntervalFilter(anchor: 0, interval: 5, shrinkMin: false, shrinkMax: false))
 		
		let stepSpace : FMProjectionCartesian2D = configurator.space(withDimensionIds: [dateDim,stepDim]) { (dimId) -> FMProjectionUpdater? in
			if(dimId == dateDim) {
				return self.dateUpdater
			}
			return self.stepUpdater
		}
		
		let weightSpace : FMProjectionCartesian2D = configurator.space(withDimensionIds: [dateDim, weightDim]) { (dimId) -> FMProjectionUpdater? in
			return self.weightUpdater
		}
		
		let pressureSpace : FMProjectionCartesian2D = configurator.space(withDimensionIds: [dateDim, pressureDim]) { (dimId) -> FMProjectionUpdater? in
			return self.pressureUpdater
		}
		
		let stepBar = configurator.addAttributedBar(toSpace: stepSpace, series: stepSeries!, attributesCapacity: 3)
		let weightLine = configurator.addAttributedLine(toSpace: weightSpace, series: weightSeries!, attributesCapacity: 2)
		let weightPoint = configurator.addAttributedPoint(toSpace: weightSpace, series: weightSeries!, attributesCapacity: 2)
		let systolicLine = configurator.addLine(toSpace: pressureSpace, series: systolicSeries!)
		let diastolicLine = configurator.addLine(toSpace: pressureSpace, series: diastolicSeries!)
		let systolicPoint = configurator.setPointToLine(systolicLine)
		let diastolicPoint = configurator.setPointToLine(diastolicLine)
		
		let weightColor : vector_float4 = UIColor(red: 0.4, green: 0.7, blue: 0.9, alpha: 1.0).vector()
		let systolicColor = UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0).vector()
		let diastolicColor = UIColor(red: 0.9, green: 0.4, blue: 0.2, alpha: 1.0).vector()
		let stepColor = UIColor(hue: 0.5, saturation: 0.5, brightness: 0.7, alpha: 1).vector()
		
		stepBar.attributesArray[0].setBarWidth(20)
		stepBar.attributesArray[0].setCornerRadius(5, rt: 5, lb: 0, rb: 0)
		stepBar.attributesArray[0].setColor(UIColor(hue: 0.5, saturation: 0.1, brightness: 0.7, alpha: 1))
		stepBar.attributesArray[1].setBarWidth(20)
		stepBar.attributesArray[1].setCornerRadius(5, rt: 5, lb: 0, rb: 0)
		stepBar.attributesArray[1].setColor(UIColor(hue: 0.5, saturation: 0.3, brightness: 0.7, alpha: 1))
		stepBar.attributesArray[2].setBarWidth(20)
		stepBar.attributesArray[2].setCornerRadius(5, rt: 5, lb: 0, rb: 0)
		stepBar.attributesArray[2].setColor(UIColor(hue: 0.5, saturation: 0.5, brightness: 0.7, alpha: 1))
		weightLine.attributesArray[0].setWidth(8)
		weightLine.attributesArray[0].setColorVec(weightColor)
		weightLine.attributesArray[1].setWidth(6)
		weightLine.attributesArray[1].setColorVec(weightColor)
		weightLine.attributesArray[1].setDashLineLength(0.001)
		weightLine.attributesArray[1].setDashSpaceLength(1)
		weightLine.attributesArray[1].setDashRepeatAnchor(1)
		weightLine.attributesArray[1].setDashLineAnchor(0)
		
		weightLine.conf.setAlpha(0.6)
		weightLine.conf.enableOverlay = true
		
		configurePointAttributes(weightPoint.attributesArray[0], innerRadius: 8, outerColor: weightColor)
		configurePointAttributes(weightPoint.attributesArray[1], innerRadius: 8, outerColor: weightColor)

		systolicLine.conf.enableOverlay = true
		systolicLine.attributes.setColorVec(systolicColor)
		configurePointAttributes(systolicPoint, innerRadius: 6, outerColor: systolicColor)
		diastolicLine.conf.enableOverlay = true
		diastolicLine.attributes.setColorVec(diastolicColor)
		configurePointAttributes(diastolicPoint, innerRadius: 6, outerColor: diastolicColor)
		
		let weightConf = FMBlockAxisConfigurator(relativePosition: 0, tickAnchor: 0, minorTicksFreq: 0, maxTickCount: 5, intervalOfInterval: 1)
		let weightSize = CGSize(width: 45, height: 25)
		let weightAttributes = [NSForegroundColorAttributeName : UIColor(vector:weightColor)!]
		let stepAttributes = [NSForegroundColorAttributeName : UIColor(vector:stepColor)!]
		let stepProjection = configurator.dimension(withId:stepDim)!
		let weightProjection = configurator.dimension(withId:weightDim)!
		let weightAxis = configurator.addAxisToDimension(withId:weightDim, belowSeries: false, configurator: weightConf, labelFrameSize: weightSize, labelBufferCount: 12) {
			(val, index, lastIndex, projection) -> [NSMutableAttributedString] in
			let strWeight = String(format: "%.0fkg", Float(val))
			let strStep = String(format: "%.0f歩", Float(weightProjection.convertValue(val, to: stepProjection)))
			return [NSMutableAttributedString(string: strWeight, attributes: weightAttributes), NSMutableAttributedString(string: strStep, attributes: stepAttributes)]
		}
		weightAxis!.axis.axisAttributes.setColorVec(weightColor)
		weightAxis!.axis.majorTickAttributes.setColorVec(weightColor)
		weightAxis!.axis.majorTickAttributes.setLengthModifierStart(0, end: 1)
		let weightLabel = configurator.axisLabels(to: weightAxis!)!.first!
		weightLabel.setFont(UIFont.systemFont(ofSize: 9, weight: UIFontWeightMedium))
		weightLabel.setFrameAnchorPoint(CGPoint(x: 1, y: 0.5))
		weightLabel.setFrameOffset(CGPoint(x: -5, y: 0))
		weightLabel.textAlignment = CGPoint(x: 1, y: 0.5)
		self.weightLabel = weightLabel
		
		let pressureConf = FMBlockAxisConfigurator(relativePosition: 1, tickAnchor: 0, minorTicksFreq: 0, maxTickCount: 5, intervalOfInterval: 5)
		let pressureSize = CGSize(width: 30, height: 25)
		let pressureAttributes = [NSForegroundColorAttributeName : UIColor(vector:systolicColor)!]
		let str2 = NSMutableAttributedString(string: "mg/dL", attributes: pressureAttributes)
		let pressureAxis = configurator.addAxisToDimension(withId: pressureDim, belowSeries: false, configurator: pressureConf, labelFrameSize: pressureSize, labelBufferCount: 12) {
			(val, index, lastIndex, projection) -> [NSMutableAttributedString] in
			let str1 = String(format: "%.0f", Float(val))
			return [NSMutableAttributedString(string: str1, attributes: pressureAttributes), str2]
		}
		pressureAxis!.axis.axisAttributes.setColorVec(systolicColor)
		pressureAxis!.axis.majorTickAttributes.setColorVec(systolicColor)
		let pressureLabel = configurator.axisLabels(to: pressureAxis!)!.first!
		pressureLabel.setFont(UIFont.systemFont(ofSize: 9, weight: UIFontWeightMedium))
		pressureLabel.setFrameAnchorPoint(CGPoint(x: 0, y: 0.5))
		pressureLabel.setFrameOffset(CGPoint(x: 5, y: 0))
		pressureLabel.textAlignment = CGPoint(x: 0, y: 0.5)
		
		let dateConf = FMBlockAxisConfigurator(relativePosition: 0, tickAnchor: 0, fixedInterval: daySec, minorTicksFreq: 0)
		let dateSize = CGSize(width: 30, height: 15)
		let dateFmt = DateFormatter()
		dateFmt.dateFormat = "M/d"
		let dateAxis = configurator.addAxisToDimension(withId: dateDim, belowSeries:false, configurator:dateConf, labelFrameSize: dateSize, labelBufferCount: 24) {
			(val, index, lastIndex, projection) -> [NSMutableAttributedString] in
			let date = NSDate(timeInterval: TimeInterval(val), since: self.refDate!)
			let str = dateFmt.string(from: date as Date)
			return [NSMutableAttributedString(string: str)]
		}
		let dateLabel = configurator.axisLabels(to: dateAxis!)!.first!
		dateLabel.setFont(UIFont.systemFont(ofSize: 9, weight: UIFontWeightThin))
		dateLabel.setFrameOffset(CGPoint(x: 0, y: 5))
		
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
		
		let refDate : Date = getStartOfDate(Date())
		self.refDate = refDate
		var interval : DateComponents = DateComponents()
		interval.day = 1
		let step = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
		let weight = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!
		let systolic = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureSystolic)!
		let diastolic = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureDiastolic)!
		
		let sort = SortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
		
		let stepQuery = HKStatisticsCollectionQuery(quantityType: step, quantitySamplePredicate: nil, options: HKStatisticsOptions.cumulativeSum, anchorDate: refDate, intervalComponents: interval)
		stepQuery.initialResultsHandler = { query, results, error in
			if let collection = results {
				self.stepSeries?.reserve(UInt(collection.statistics().count))
				for statistic in collection.statistics() {
					if let quantity = statistic.sumQuantity() {
						let yValue = CGFloat(quantity.doubleValue(for: HKUnit.count()))
						let xValue = CGFloat(statistic.startDate.timeIntervalSince(refDate))
						let attr : UInt = (yValue < 5000) ? (0) : ((yValue < 10000) ? 1 : 2)
						self.stepSeries?.add(CGPoint(x: xValue, y: yValue), attrIndex: attr)
						self.stepUpdater?.addSourceValue(yValue, update: false)
						self.dateUpdater?.addSourceValue(xValue, update: false)
					}
				}
				self.stepUpdater?.updateTarget()
				self.weightLabel?.clearCache()
				self.windowPos?.reset()
				self.dateUpdater?.updateTarget()
				self.metalView.setNeedsDisplay()
			}
		}
		
		let kg = HKUnit.gramUnit(with: HKMetricPrefix.kilo)
		let weightQuery = HKSampleQuery(sampleType:weight, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { (query, samples, error) -> Void in
			if let array = samples {
				self.weightSeries?.reserve(UInt(array.count))
				var idx : UInt = 0;
				for sample in (array as! [HKQuantitySample]) {
					let x = CGFloat(sample.startDate.timeIntervalSince(refDate))
					let val = CGFloat(sample.quantity.doubleValue(for: kg))
					self.weightSeries?.add(CGPoint(x: x, y: val), attrIndex: idx%2)
					self.weightUpdater?.addSourceValue(val, update: false)
					self.dateUpdater?.addSourceValue(x, update: false)
					idx += 1
				}
				self.weightUpdater?.updateTarget()
				self.weightLabel?.clearCache()
				self.windowPos?.reset()
				self.dateUpdater?.updateTarget()
				self.metalView.setNeedsDisplay()
			}
		}
		let mmHg = HKUnit.millimeterOfMercury()
		let systolicQuery = HKSampleQuery(sampleType:systolic, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { (query, samples, error) -> Void in
			if let array = samples {
				self.systolicSeries?.reserve(UInt(array.count))
				for sample in (array as! [HKQuantitySample]) {
					let x = CGFloat(sample.startDate.timeIntervalSince(refDate))
					let val = CGFloat(sample.quantity.doubleValue(for: mmHg))
					self.systolicSeries?.add(CGPoint(x: x, y: val))
					self.pressureUpdater?.addSourceValue(val, update: false)
					self.dateUpdater?.addSourceValue(x, update: false)
				}
				self.pressureUpdater?.updateTarget()
				self.windowPos?.reset()
				self.dateUpdater?.updateTarget()
				self.metalView.setNeedsDisplay()
			}
		}
		let diastolicQuery = HKSampleQuery(sampleType:diastolic, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { (query, samples, error) -> Void in
			if let array = samples {
				self.diastolicSeries?.reserve(UInt(array.count))
				for sample in (array as! [HKQuantitySample]) {
					let x = CGFloat(sample.startDate.timeIntervalSince(refDate))
					let val = CGFloat(sample.quantity.doubleValue(for: mmHg))
					self.diastolicSeries?.add(CGPoint(x: x, y: val))
					self.pressureUpdater?.addSourceValue(val, update: false)
					self.dateUpdater?.addSourceValue(x, update: false)
				}
				self.pressureUpdater?.updateTarget()
				self.windowPos?.reset()
				self.dateUpdater?.updateTarget()
				self.metalView.setNeedsDisplay()
			}
		}
		store.execute(stepQuery)
		store.execute(weightQuery)
		store.execute(systolicQuery)
		store.execute(diastolicQuery)
	}
	
	let calendar : Calendar = Calendar(calendarIdentifier: Calendar.Identifier.gregorian)!
	func getStartOfDate(_ date : Date) -> Date {
		let comp : DateComponents = calendar.components([.year, .month, .day], from: date)
		return calendar.date(from: comp)!
	}
	
	func configurePointAttributes(_ attrs : FMUniformPointAttributes, innerRadius : Float, outerColor : vector_float4) {
		attrs.setInnerRadius(innerRadius)
		attrs.setOuterRadius(innerRadius * 1.5)
		attrs.setInnerColor(UIColor.white())
		attrs.setOuterColorVec(outerColor)
	}
	
	@IBAction func chartTapped(_ sender: UITapGestureRecognizer) {
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		coordinator.animate(
			alongsideTransition: { (context) in
				self.dateUpdater?.updateTarget()
				self.metalView.setNeedsDisplay()
			}, completion: nil)
	}
	
}
