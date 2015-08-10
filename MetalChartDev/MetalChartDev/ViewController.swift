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
	
	var chart : MetalChart = MetalChart()
	let resource : DeviceResource = DeviceResource.defaultResource()
    
	override func viewDidLoad() {
		super.viewDidLoad()
        metalView.device = resource.device
        metalView.sampleCount = 2
        let v : Double = 0.5;
        let alpha : Double = 1;
        metalView.clearColor = MTLClearColorMake(v,v,v,alpha)
        metalView.clearDepth = 0
		metalView.colorPixelFormat = MTLPixelFormat.BGRA8Unorm
        metalView.depthStencilPixelFormat = MTLPixelFormat.Depth32Float_Stencil8;
		metalView.enableSetNeedsDisplay = false
		metalView.paused = false
		metalView.preferredFramesPerSecond = 30
		
		setupChart()
		metalView.delegate = chart
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func setupChart() {
		
		let yRange : CGFloat = CGFloat(5)
		let dimX = MCDimensionalProjection(dimensionId: 1, minValue: -1, maxValue: 1)
		let dimY = MCDimensionalProjection(dimensionId: 2, minValue: -yRange, maxValue: yRange)
		let space = MCSpatialProjection(dimensions: [dimX, dimY])
		
		let engine = LineEngine(resource: resource)
		let series = OrderedSeries(resource: resource, vertexCapacity: 1<<12)
		let line = OrderedPolyLine(resource: resource, orderedSeries: series, engine: engine)
		line.setSampleAttributes()
		
		let lineSeries = MCLineSeries(line: line)
		
		let xUpdater = MCProjectionUpdater(target: dimX)
		xUpdater.addRestriction(MCLengthRestriction(length: 256, anchor: 1, offset:32))
		xUpdater.addRestriction(MCAlternativeSourceRestriction(minValue: -1, maxValue: 1, expandMin: true, expandMax: true))
		
		chart.willDraw = { (mc : MetalChart) -> Void in
			line.appendSampleData(1, maxVertexCount:512) { (Float x, Float y) in
				xUpdater.addSourceValue(CGFloat(x), update: false)
			}
			xUpdater.updateTarget()
		}
		
		chart.addSeries(lineSeries, projection: space)
	}
}

