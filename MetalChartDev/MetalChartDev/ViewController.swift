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

class ViewController: UIViewController {

	@IBOutlet var metalView: MTKView!
    @IBOutlet var panRecognizer: UIPanGestureRecognizer!
    @IBOutlet var pinchRecognizer: UIPinchGestureRecognizer!
    @IBOutlet var tapRecognizer: UITapGestureRecognizer!
    
	var chart : MetalChart = MetalChart()
	let resource : DeviceResource = DeviceResource.defaultResource()
    let animator : MCAnimator = MCAnimator();
	let asChart = false
    var firstLineAttributes : UniformLineAttributes? = nil
    
	override func viewDidLoad() {
		super.viewDidLoad()
        metalView.device = resource.device
        metalView.sampleCount = 2
        let v : Double = 0.9
        let alpha : Double = 1
        metalView.clearColor = MTLClearColorMake(v,v,v,alpha)
        metalView.clearDepth = 0
		metalView.colorPixelFormat = MTLPixelFormat.BGRA8Unorm
        metalView.depthStencilPixelFormat = MTLPixelFormat.Depth32Float_Stencil8
		metalView.enableSetNeedsDisplay = false
		metalView.paused = false
		metalView.preferredFramesPerSecond = 60
		metalView.addGestureRecognizer(panRecognizer)
		metalView.addGestureRecognizer(pinchRecognizer)
        metalView.addGestureRecognizer(tapRecognizer)
		
		setupChart()
		metalView.delegate = chart
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func setupChart() {
		
		let restriction = MCDefaultInterpreterRestriction(scaleMin: CGSize(width: 1,height: 1), max: CGSize(width: 2,height: 2), translationMin: CGPoint(x: -1.5,y: -1.5), max: CGPoint(x: 1.5,y: 1.5))
		let interpreter = MCGestureInterpreter(panRecognizer: panRecognizer, pinchRecognizer: pinchRecognizer, restriction: restriction)
		interpreter.orientationStepDegree = 1
		
		if (asChart) {
			let yRange : CGFloat = CGFloat(5)
			let dimX = MCDimensionalProjection(dimensionId: 1, minValue: -1, maxValue: 1)
			let dimY = MCDimensionalProjection(dimensionId: 2, minValue: -yRange, maxValue: yRange)
			let space = MCSpatialProjection(dimensions: [dimX, dimY])
			
			let vertCapacity : UInt = 1<<9
			let vertLength = 1 << 8
			let vertOffset = 1 << 4
			let engine = Engine(resource: resource)
			let series = OrderedSeries(resource: resource, vertexCapacity: vertCapacity)
			let line = OrderedPolyLinePrimitive(engine: engine, orderedSeries: series, attributes:nil)
			line.setSampleAttributes()
            
//            let pointAttributes = UniformPoint(resource: resource)
//            pointAttributes.setOuterColor(0, green: 0, blue: 0, alpha: 0)
//            line.pointAttributes = pointAttributes
            
            let overlaySeries = OrderedSeries(resource: resource, vertexCapacity: vertCapacity)
            let overlayLine = OrderedPolyLinePrimitive(engine: engine, orderedSeries: overlaySeries, attributes:nil)
            overlayLine.setSampleAttributes()
            overlayLine.attributes.setColorWithRed(1.0, green: 0.5, blue: 0.2, alpha: 0.5)
            overlayLine.attributes.setWidth(3)
			
			let xAxisConf = MCBlockAxisConfigurator() { (uniform, dimension, orthogonal, isFirst) -> Void in
				uniform.majorTickInterval = CFloat(1<<6)
				uniform.axisAnchorValue = 0
				uniform.tickAnchorValue = 0
			}
			
			let yAxisConf = MCBlockAxisConfigurator() { (uniform, dimension, orthogonal, isFirst) -> Void in
				let l = dimension.length()
				uniform.majorTickInterval = CFloat(l / 4)
				uniform.axisAnchorValue = CFloat(orthogonal.min)
				uniform.tickAnchorValue = 0
			}
			
			let xAxis = MCAxis(engine: engine, projection: space, dimension: 1, configuration:xAxisConf)
			let yAxis = MCAxis(engine: engine, projection: space, dimension: 2, configuration:yAxisConf)
            
            xAxis.setMinorTickCountPerMajor(4)
			
			let xUpdater = MCProjectionUpdater(target: dimX)
			xUpdater.addRestriction(MCLengthRestriction(length: CGFloat(vertLength), anchor: 1, offset:CGFloat(vertOffset)))
			xUpdater.addRestriction(MCSourceRestriction(minValue: -1, maxValue: 1, expandMin: true, expandMax: true))
			
			chart.padding = RectPadding(left: 30, top: 60, right: 30, bottom: 60)
			
			chart.willDraw = { (mc : MetalChart) -> Void in
                line.appendSampleData((1<<0), maxVertexCount:vertCapacity, mean:CGFloat(+0.3), variance:CGFloat(0.75)) { (Float x, Float y) in
					xUpdater.addSourceValue(CGFloat(x), update: false)
				}
                overlayLine.appendSampleData((1<<0), maxVertexCount:vertCapacity, mean:CGFloat(-0.3), variance: 1) { (Float x, Float y) in
                    xUpdater.addSourceValue(CGFloat(x), update: false)
                }
				xUpdater.updateTarget()
			}
			
			let lineSeries = MCLineSeries(line: line)
            let overlayLineSeries = MCLineSeries(line: overlayLine)
            
			chart.addSeries(lineSeries, projection: space)
            chart.addSeries(overlayLineSeries, projection: space)
			chart.addPostRenderable(yAxis)
			chart.addPostRenderable(xAxis)
            
            firstLineAttributes = line.attributes
            chart.bufferHook = animator
			
		} else {
            chart.padding = RectPadding(left: 30, top: 30, right: 30, bottom: 30)
			
			let offsetX = CGFloat(0)
			let dimX = MCDimensionalProjection(dimensionId: 1, minValue: -1 + offsetX, maxValue: 1 + offsetX)
			let dimY = MCDimensionalProjection(dimensionId: 2, minValue: -1, maxValue: 1)
			let space = MCSpatialProjection(dimensions: [dimX, dimY])
			
			let xUpdater = MCProjectionUpdater(target: dimX)
			xUpdater.addRestriction(MCUserInteractiveRestriction(gestureInterpreter: interpreter, orientation: CGFloat(0)))
			xUpdater.addRestriction(MCLengthRestriction(length: 2, anchor: 0, offset: offsetX))
			
			let yUpdater = MCProjectionUpdater(target: dimY)
			yUpdater.addRestriction(MCUserInteractiveRestriction(gestureInterpreter: interpreter, orientation: CGFloat(M_PI_2)))
			yUpdater.addRestriction(MCLengthRestriction(length: 2, anchor: 0, offset: 0))
			
			let interaction = MCSimpleBlockInteraction() { (interpreter) -> Void in
				xUpdater.updateTarget()
				yUpdater.updateTarget()
			}
			interpreter.addInteraction(interaction)
			
			let engine = Engine(resource: resource)
			let series = OrderedSeries(resource: resource, vertexCapacity: 1<<6)
			let line = OrderedPolyLinePrimitive(engine: engine, orderedSeries: series, attributes:nil)
			line.setSampleData()
			series.info.count = 5
			line.attributes.setWidth(10)
			
			let series2 = OrderedSeries(resource: resource, vertexCapacity: (1<<4))
			series2.addPoint(CGPointMake(0.5, 0.5))
			let bar = OrderedBarPrimitive(engine: engine, series: series2, attributes:nil)
			bar.attributes.setBarWidth(10)
			bar.attributes.setBarDirection(CGPointMake(0, 1))
			bar.attributes.setAnchorPoint(CGPointMake(0, 0))
			bar.attributes.setCornerRadius(3, rt: 3, lb: 0, rb: 0)
			let barSeries = MCBarSeries(bar: bar)
            
            let pointAttributes = UniformPoint(resource: resource)
            line.pointAttributes = pointAttributes
			
			let xAxisConf = MCBlockAxisConfigurator(fixedAxisAnchor: 0, tickAnchor: 0, fixedInterval: 0.5, minorTicksFreq: 5)
			
			let xAxis = MCAxis(engine: engine, projection: space, dimension: 1, configuration:xAxisConf)
			
			xAxis.setMinorTickCountPerMajor(3)
			
            let labelDelegate : MCAxisLabelDelegate = MCAxisLabelBlockDelegate() { (value : CGFloat, dimension : MCDimensionalProjection) -> NSMutableAttributedString in
                let str = NSMutableAttributedString(string: String(format: "%.1f", Float(value)))
                return str
            }
            let text = MCAxisLabel(engine: engine, frameSize:CGSizeMake(20, 10), bufferCapacity:5, labelDelegate:labelDelegate)
            text.setFrameAnchorPoint(CGPoint(x: 0.5, y: 0.0))
            text.setFrameOffset(CGPointMake(0, 5))
            text.setFont(UIFont.systemFontOfSize(10))
			xAxis.decoration = text
			
			let lineSeries = MCLineSeries(line: line)
			chart.addSeries(lineSeries, projection: space)
			chart.addSeries(barSeries, projection: space)
            
            let rect = PlotRect(engine: engine)
            rect.attributes.setColor(1, green: 1, blue: 1, alpha: 1)
            rect.attributes.setCornerRadius(5, rt: 5, lb: 0, rb: 5)
            let plotArea = MCPlotArea(rect: rect)
			
			chart.addPostRenderable(xAxis)
            chart.addPreRenderable(plotArea)
		}
	}
    
    @IBAction func chartTapped(sender: UITapGestureRecognizer) {
        let anim = MCBlockAnimation(duration: 0.5, delay: 0.1) { (progress) in
            let alpha : CFloat = CFloat( 2 * fabs(0.5 - progress) )
            self.firstLineAttributes?.setAlpha(alpha)
        }
        animator.addAnimation(anim)
    }
    
}
