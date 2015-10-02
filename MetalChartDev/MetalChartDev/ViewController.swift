//
//  ViewController.swift
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/03.
//  Copyright © 2015年 freaks. All rights reserved.
//

import UIKit
import Metal
import MetalKit
import FMChart

class ViewController: UIViewController {

	@IBOutlet var metalView: MTKView!
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
        chart.clearDepth = 1;
		
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
			let yRange : CGFloat = CGFloat(5)
			let dimX = FMDimensionalProjection(dimensionId: 1, minValue: -1, maxValue: 1)
			let dimY = FMDimensionalProjection(dimensionId: 2, minValue: -yRange, maxValue: yRange)
			let space = FMSpatialProjection(dimensions: [dimX, dimY])
			
			let vertCapacity : UInt = 1<<9
			let vertLength = 1 << 8
			let vertOffset = 1 << 4
			let series = OrderedSeries(resource: resource, vertexCapacity: vertCapacity)
			let line = OrderedPolyLinePrimitive(engine: engine, orderedSeries: series, attributes:nil)
            
            let overlaySeries = OrderedSeries(resource: resource, vertexCapacity: vertCapacity)
            let overlayLine = OrderedPolyLinePrimitive(engine: engine, orderedSeries: overlaySeries, attributes:nil)
            overlayLine.attributes.setColorWithRed(1.0, green: 0.5, blue: 0.2, alpha: 0.5)
            overlayLine.attributes.setWidth(3)
			
			let xAxisConf = FMBlockAxisConfigurator() { (uniform, dimension, orthogonal, isFirst) -> Void in
				uniform.majorTickInterval = CFloat(1<<6)
				uniform.axisAnchorValue = 0
				uniform.tickAnchorValue = 0
			}
			
			let yAxisConf = FMBlockAxisConfigurator() { (uniform, dimension, orthogonal, isFirst) -> Void in
				let l = dimension.length()
				uniform.majorTickInterval = CFloat(l / 4)
				uniform.axisAnchorValue = CFloat(orthogonal.min)
				uniform.tickAnchorValue = 0
			}
			
			let xAxis = FMAxis(engine: engine, projection: space, dimension: 1, configuration:xAxisConf)
			let yAxis = FMAxis(engine: engine, projection: space, dimension: 2, configuration:yAxisConf)
            
            xAxis.setMinorTickCountPerMajor(4)
			
			let xUpdater = FMProjectionUpdater(target: dimX)
            xUpdater.addRestrictionToLast(FMSourceRestriction(minValue: -1, maxValue: 1, expandMin: true, expandMax: true))
			xUpdater.addRestrictionToLast(FMLengthRestriction(length: CGFloat(vertLength), anchor: 1, offset:CGFloat(vertOffset)))
			
			chart.padding = RectPadding(left: 30, top: 60, right: 30, bottom: 60)
			
			chart.willDraw = { (FM : MetalChart) -> Void in
                line.appendSampleData((1<<0), maxVertexCount:vertCapacity, mean:CGFloat(+0.3), variance:CGFloat(0.75)) { (Float x, Float y) in
					xUpdater.addSourceValue(CGFloat(x), update: false)
				}
                overlayLine.appendSampleData((1<<0), maxVertexCount:vertCapacity, mean:CGFloat(-0.3), variance: 1) { (Float x, Float y) in
                    xUpdater.addSourceValue(CGFloat(x), update: false)
                }
				xUpdater.updateTarget()
			}
			
			let lineSeries = FMLineSeries(line: line)
            let overlayLineSeries = FMLineSeries(line: overlayLine)
            
			chart.addSeries(lineSeries, projection: space)
            chart.addSeries(overlayLineSeries, projection: space)
			chart.addPostRenderable(yAxis)
			chart.addPostRenderable(xAxis)
            
            firstLineAttributes = line.attributes
            chart.bufferHook = animator
			
		} else {
			let space : FMSpatialProjection = configurator.spaceWithDimensionIds([1, 2]) { (dimensionID) -> FMProjectionUpdater? in
				let updater = FMProjectionUpdater()
				updater.addRestrictionToLast(FMLengthRestriction(length: 2, anchor: 0, offset: 0))
				return updater
			}
			configurator.connectSpace([space], toInterpreter: interpreter)
			
			let lineSeries = FMLineSeries.orderedSeriesWithCapacity(4, engine: engine)
			lineSeries.attributes.setWidth(10)
			for idx in 0 ..< 4  {
				lineSeries.series?.addPoint(CGPointMake(CGFloat(Double(idx%2) - 0.5), CGFloat(Double(idx/2) - 0.5)))
			}
			lineSeries.series?.info().count = 5;
			
			let barSeries = FMBarSeries.orderedSeriesWithCapacity((1<<4), engine: engine)
			barSeries.attributes.setBarWidth(10)
			barSeries.attributes.setCornerRadius(3, rt: 3, lb: 0, rb: 0)
			barSeries.bar.series()?.addPoint(CGPointMake(0.5, 0.75))
			barSeries.bar.series()?.addPoint(CGPointMake(0.75, 0.5))
			
			let xAxisConf = FMBlockAxisConfigurator(fixedAxisAnchor: 0, tickAnchor: 0, fixedInterval: 0.5, minorTicksFreq: 5)
			configurator.addAxisToDimensionWithId(1, belowSeries: true, configurator: xAxisConf) { (value : CGFloat, dimension : FMDimensionalProjection) -> NSMutableAttributedString in
				let str = NSMutableAttributedString(string: String(format: "%.1f", Float(value)))
				return str
			}
			
			let rect = configurator.addPlotAreaWithColor(UIColor.whiteColor())
			rect.attributes.setCornerRadius(5, rt: 5, lb: 5, rb: 5)
			
			chart.addSeriesArray([lineSeries, barSeries], projections: [space, space])
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
