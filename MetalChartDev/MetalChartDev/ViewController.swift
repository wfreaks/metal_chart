//
//  ViewController.swift
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/03.
//  Copyright © 2015年 freaks. All rights reserved.
//

import UIKit
import Metal
import FMChartSupport
import HealthKit

class ViewController: UIViewController {

	@IBOutlet var metalView: MetalView!
    @IBOutlet var panRecognizer: UIPanGestureRecognizer!
    @IBOutlet var pinchRecognizer: UIPinchGestureRecognizer!
    @IBOutlet var tapRecognizer: UITapGestureRecognizer!
    
	var chart : MetalChart = MetalChart()
	var chartConf : FMConfigurator? = nil
	let resource : FMDeviceResource = FMDeviceResource.defaultResource()!
    let animator : FMAnimator = FMAnimator()
	let store : HKHealthStore = HKHealthStore()
	var interpreter : FMGestureInterpreter? = nil
	
	let seriesCapacity : UInt = 256
	var stepSeries : FMOrderedSeries? = nil
	var weightSeries : FMOrderedSeries? = nil
	var systolicSeries : FMOrderedSeries? = nil
	var diastolicSeries : FMOrderedSeries? = nil
	
	var stepBar : FMBarSeries? = nil
	var weightLine : FMLineSeries? = nil
	var systolicLine : FMLineSeries? = nil
	var diastolicLine : FMLineSeries? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
        metalView.device = resource.device
        metalView.sampleCount = 2
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
		let engine = FMEngine(resource: resource)
		let fps = 0;
		let configurator : FMConfigurator = FMConfigurator(chart:chart, engine:engine, view:metalView, preferredFps: fps)
		chartConf = configurator
		chart.padding = RectPadding(left: 30, top: 30, right: 30, bottom: 30)
		chart.bufferHook = animator
		
		configurator.addPlotAreaWithColor(UIColor.whiteColor()).attributes.setCornerRadius(5)
        
		let restriction = FMDefaultInterpreterRestriction(scaleMin: CGSize(width: 1,height: 1), max: CGSize(width: 10,height: 10), translationMin: CGPoint(x: -1.5,y: -1.5), max: CGPoint(x: 1.5,y: 1.5))
		let interpreter = configurator.addInterpreterToPanRecognizer(panRecognizer, pinchRecognizer: pinchRecognizer, stateRestriction: restriction)
		self.interpreter = interpreter
		
		stepSeries = configurator.createSeries(seriesCapacity)
		weightSeries = configurator.createSeries(seriesCapacity)
		systolicSeries = configurator.createSeries(seriesCapacity)
		diastolicSeries = configurator.createSeries(seriesCapacity)
		
		let dateDim = 1
		let stepDim = 2
		let weightDim = 3
		let pressureDim = 4
		
		let dateUpdator = FMProjectionUpdater()
		let daySec : CGFloat = 24 * 60 * 60
		dateUpdator.addRestrictionToLast(FMSourceRestriction(minValue: -7 * daySec, maxValue: daySec, expandMin: true, expandMax: true))
		
		let stepUpdator = FMProjectionUpdater()
		stepUpdator.addRestrictionToLast(FMSourceRestriction(minValue: 0, maxValue: 2000, expandMin: true, expandMax: true))
		stepUpdator.addRestrictionToLast(FMIntervalRestriction(anchor: 0, interval: 1000, shrinkMin: false, shrinkMax: false))
		
		let weightUpdator = FMProjectionUpdater()
		weightUpdator.addRestrictionToLast(FMSourceRestriction(minValue: 50, maxValue: 60, expandMin: false, expandMax: false))
		weightUpdator.addRestrictionToLast(FMIntervalRestriction(anchor: 0, interval: 5, shrinkMin: false, shrinkMax: false))
		
		let pressureUpdator = FMProjectionUpdater()
		pressureUpdator.addRestrictionToLast(FMSourceRestriction(minValue: 60, maxValue: 80, expandMin: false, expandMax: false))
		pressureUpdator.addRestrictionToLast(FMIntervalRestriction(anchor: 0, interval: 20, shrinkMin: false, shrinkMax: false))
 		
		let stepSpace : FMProjectionCartesian2D = configurator.spaceWithDimensionIds([dateDim,stepDim]) { (dimId) -> FMProjectionUpdater? in
			if(dimId == dateDim) {
				return dateUpdator
			}
			return stepUpdator
		}
		
		let weightSpace : FMProjectionCartesian2D = configurator.spaceWithDimensionIds([dateDim, weightDim]) { (dimId) -> FMProjectionUpdater? in
			return weightUpdator
		}
		
		let pressureSpace : FMProjectionCartesian2D = configurator.spaceWithDimensionIds([dateDim, pressureDim]) { (dimId) -> FMProjectionUpdater? in
			return pressureUpdator
		}
		
		stepBar = configurator.addBarToSpace(stepSpace, series: stepSeries!)
		weightLine = configurator.addLineToSpace(weightSpace, series: weightSeries!)
		systolicLine = configurator.addLineToSpace(pressureSpace, series: systolicSeries!)
		diastolicLine = configurator.addLineToSpace(pressureSpace, series: diastolicSeries!)
		
		let dateConf = FMBlockAxisConfigurator(relativePosition: 0, tickAnchor: 0, fixedInterval: daySec, minorTicksFreq: 0)
		let axis = configurator.addAxisToDimensionWithId(dateDim, belowSeries: false, configurator: dateConf, label: nil)
		
		configurator.connectSpace([stepSpace, weightSpace, pressureSpace], toInterpreter: interpreter)
	}
	
	func loadData() {
		stepSeries?.info.clear()
		weightSeries?.info.clear()
		systolicSeries?.info.clear()
		diastolicSeries?.info.clear()
		
		let refDate : NSDate = getStartOfDate(NSDate())
		let step = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!
		let weight = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!
		let pressure = HKCorrelationType.correlationTypeForIdentifier(HKCorrelationTypeIdentifierBloodPressure)!
		
		let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
		
		let stepQuery = HKStatisticsQuery(quantityType: step, quantitySamplePredicate: <#T##NSPredicate?#>, options: <#T##HKStatisticsOptions#>, completionHandler: <#T##(HKStatisticsQuery, HKStatistics?, NSError?) -> Void#>)
		
		let kg = HKUnit(fromMassFormatterUnit: NSMassFormatterUnit.Kilogram)
		let weightQuery = HKSampleQuery(sampleType:weight, predicate: nil, limit: Int(seriesCapacity), sortDescriptors: [sort]) { (query, samples, error) -> Void in
			if let array = samples {
				for sample in (array as! [HKQuantitySample]) {
					self.weightSeries?.addPoint(CGPointMake(CGFloat(sample.startDate.timeIntervalSinceDate(refDate)), CGFloat(sample.quantity.doubleValueForUnit(kg))))
				}
				self.metalView.setNeedsDisplay()
			}
		}
		store.executeQuery(weightQuery)
//		let pressureQuery = HKCorrelationQuery(type: pressure, predicate: nil, samplePredicates: nil) { (query, correlations, error) -> Void in
//		}
//		
//		let components = NSDateComponents()
//		components.day = 1
//		let stepQuery = HKStatisticsCollectionQuery(quantityType: step, quantitySamplePredicate: nil, options: HKStatisticsOptions.CumulativeSum, anchorDate: refDate, intervalComponents: components)
		
	}
	
	let calendar : NSCalendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
	func getStartOfDate(date : NSDate) -> NSDate {
		let comp : NSDateComponents = calendar.components([.Year, .Month, .Day], fromDate: date)
		return calendar.dateFromComponents(comp)!
	}
    
    @IBAction func chartTapped(sender: UITapGestureRecognizer) {
//        let anim = FMBlockAnimation(duration: 0.5, delay: 0.1) { (progress) in
//            let alpha : CFloat = CFloat( 2 * fabs(0.5 - progress) )
//        }
//        animator.addAnimation(anim)
    }
    
}
