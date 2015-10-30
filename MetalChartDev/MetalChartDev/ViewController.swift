//
//  ViewController.swift
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/03.
//  Copyright © 2015年 freaks. All rights reserved.
//

import UIKit
import Metal
import FMChart
import MetalKit

class ViewController: UIViewController {

	@IBOutlet var metalView: MetalView!
    @IBOutlet var panRecognizer: UIPanGestureRecognizer!
    @IBOutlet var pinchRecognizer: UIPinchGestureRecognizer!
    @IBOutlet var tapRecognizer: UITapGestureRecognizer!
    
	var chart : MetalChart = MetalChart()
	let resource : DeviceResource = DeviceResource.defaultResource()!
    let animator : FMAnimator = FMAnimator();
	let asChart = false
    var firstLineAttributes : UniformLineAttributes? = nil
    
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

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func setupChart() {
		let engine = Engine(resource: resource)
		let configurator : FMConfigurator = FMConfigurator(chart:chart, engine:engine, view:metalView, preferredFps: 60)
		
		let restriction = FMDefaultInterpreterRestriction(scaleMin: CGSize(width: 1,height: 1), max: CGSize(width: 2,height: 2), translationMin: CGPoint(x: -1.5,y: -1.5), max: CGPoint(x: 1.5,y: 1.5))
		let interpreter = configurator.addInterpreterToPanRecognizer(panRecognizer, pinchRecognizer: pinchRecognizer, stateRestriction: restriction)
		
		chart.padding = RectPadding(left: 30, top: 30, right: 30, bottom: 30)
		
		if (asChart) {
            
            let N : UInt = 9;
            let vertCapacity : UInt = 1 << N
            let vertLength = 1 << (N-1);
            let vertOffset = 1 << (N-5);
            let yRange : CGFloat = CGFloat(5)
            
            let space = configurator.spaceWithDimensionIds([1,2]) { (dimId) -> FMProjectionUpdater? in
                let updater : FMProjectionUpdater = FMProjectionUpdater()
                if(dimId == 1) {
                    updater.addRestrictionToLast(FMSourceRestriction(minValue: -1, maxValue: 1, expandMin: true, expandMax: true))
                    updater.addRestrictionToLast(FMLengthRestriction(length: CGFloat(vertLength), anchor: 1, offset:CGFloat(vertOffset)))
                } else {
                    updater.addRestrictionToLast(FMSourceRestriction( minValue: -yRange, maxValue: yRange, expandMin: true, expandMax: true))
                }
                return updater
            }
            
            let xAxisConf = FMBlockAxisConfigurator(fixedAxisAnchor: 0, tickAnchor: 0, fixedInterval: CGFloat(1<<(N-3)), minorTicksFreq: 4)
            let yAxisConf = FMBlockAxisConfigurator(relativePosition: 0, tickAnchor: 0, fixedInterval: 1, minorTicksFreq: 0)
            configurator.addAxisToDimensionWithId(2, belowSeries: false, configurator: yAxisConf, label: nil)
            configurator.addAxisToDimensionWithId(1, belowSeries: false, configurator: xAxisConf, label: nil)
            
            let lineSeries = configurator.addLineToSpace(space, series: configurator.createSeries(vertCapacity))
            let overlayLineSeries = configurator.addLineToSpace(space, series: configurator.createSeries(vertCapacity))
            overlayLineSeries.attributes.setColorWithRed(1.0, green: 0.5, blue: 0.2, alpha: 0.5)
            overlayLineSeries.attributes.enableOverlay = true
            
            lineSeries.attributes.setWidth(3)
            overlayLineSeries.attributes.setWidth(3)
			
            let xUpdater : FMProjectionUpdater = configurator.updaterWithDimensionId(1)!
            let yUpdater : FMProjectionUpdater = configurator.updaterWithDimensionId(2)!
			
			chart.willDraw = { (FM : MetalChart) -> Void in
                let line : OrderedPolyLinePrimitive = lineSeries.line as! OrderedPolyLinePrimitive
                let overlayLine : OrderedPolyLinePrimitive = overlayLineSeries.line as! OrderedPolyLinePrimitive
                line.appendSampleData((1<<(N-9)), maxVertexCount:vertCapacity, mean:CGFloat(+0.3), variance:CGFloat(0.75)) { (Float x, Float y) in
					xUpdater.addSourceValue(CGFloat(x), update: false)
				}
                overlayLine.appendSampleData((1<<(N-9)), maxVertexCount:vertCapacity, mean:CGFloat(-0.3), variance: 0.3) { (Float x, Float y) in
                    xUpdater.addSourceValue(CGFloat(x), update: false)
                }
				xUpdater.updateTarget()
                yUpdater.updateTarget()
			}
            
            configurator.addPlotAreaWithColor(UIColor.whiteColor())
            
            let yGrid = configurator.addGridLineToDimensionWithId(2, belowSeries: true, anchor: 0, interval:1)!
            yGrid.attributes.setDashLineLength(5)
            yGrid.attributes.setDashSpaceLength(5)
            
            firstLineAttributes = lineSeries.attributes
            chart.bufferHook = animator
			
		} else {
			let space : FMSpatialProjection = configurator.spaceWithDimensionIds([1, 2]) { (dimensionID) -> FMProjectionUpdater? in
				let updater = FMProjectionUpdater()
				updater.addRestrictionToLast(FMLengthRestriction(length: 2, anchor: 0, offset: 0))
				return updater
			}
            
            let dummySpace = configurator.spaceWithDimensionIds([3, 2]) { (dimensionID) -> FMProjectionUpdater? in
                let updater = FMProjectionUpdater()
                updater.addRestrictionToLast(FMLengthRestriction(length: 20, anchor: 0, offset: 0))
                return updater
            }
            configurator.connectSpace([space, dummySpace], toInterpreter: interpreter)
            let dummyDim : FMDimensionalProjection = configurator.dimensionWithId(3)!
			
            let lineSeries = configurator.addLineToSpace(space, series: configurator.createSeries(4))
            lineSeries.attributes.setWidth(2)
            lineSeries.attributes.enableOverlay = true
            lineSeries.attributes.enableDash = true;
            lineSeries.attributes.setDashLineLength(2);
            lineSeries.attributes.setDashSpaceLength(2);
			
			let barSeries = configurator.addBarToSpace(space, series: configurator.createSeries(1<<4))
			barSeries.attributes.setBarWidth(10)
			barSeries.attributes.setCornerRadius(3, rt: 3, lb: 0, rb: 0)
			
			let xAxisConf = FMBlockAxisConfigurator(fixedAxisAnchor: 0, tickAnchor: 0, fixedInterval: 0.25, minorTicksFreq: 5)
			configurator.addAxisToDimensionWithId(1, belowSeries: true, configurator: xAxisConf) { (value : CGFloat, dimension : FMDimensionalProjection) -> [NSMutableAttributedString] in
                let str_a = NSMutableAttributedString(string: String(format: "%.1f", Float(value)), attributes: [kCTForegroundColorAttributeName as String : UIColor.redColor()])
                let v = dimension.convertValue(value, to: dummyDim)
                let str_b = NSMutableAttributedString(string: String(format: "%.1f", Float(v)), attributes: [kCTForegroundColorAttributeName as String : UIColor.blueColor()])
				return [str_a, str_b]
			}
            
            configurator.addGridLineToDimensionWithId(1, belowSeries: true, anchor: 0, interval: 0.5)
            configurator.addGridLineToDimensionWithId(2, belowSeries: true, anchor: 0, interval: 0.25)
			
			let rect = configurator.addPlotAreaWithColor(UIColor.whiteColor())
			rect.attributes.setCornerRadius(10)
			
            barSeries.bar.series()?.addPoint(CGPointMake(0.5, 0.75))
            barSeries.bar.series()?.addPoint(CGPointMake(0.75, 0.5))
            for idx in 0 ..< 4  {
                lineSeries.series?.addPoint(CGPointMake(CGFloat(Double(idx%2) - 0.5), CGFloat(Double(idx/2) - 0.5)))
            }
		}
	}
    
    @IBAction func chartTapped(sender: UITapGestureRecognizer) {
        let anim = FMBlockAnimation(duration: 0.5, delay: 0.1) { (progress) in
            let alpha : CFloat = CFloat( 2 * fabs(0.5 - progress) )
            self.firstLineAttributes?.setAlpha(alpha)
        }
        animator.addAnimation(anim)
    }
    
}
