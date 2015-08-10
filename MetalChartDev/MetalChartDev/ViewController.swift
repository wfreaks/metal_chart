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
	
	var vd : ViewDelegate = ViewDelegate()
    
	override func viewDidLoad() {
		super.viewDidLoad()
        metalView.device = DeviceResource.defaultResource().device
        metalView.sampleCount = 2
        let v : Double = 0.5;
        let alpha : Double = 1;
        metalView.clearColor = MTLClearColorMake(v,v,v,alpha)
        metalView.clearDepth = 0
		metalView.colorPixelFormat = MTLPixelFormat.BGRA8Unorm
        metalView.depthStencilPixelFormat = MTLPixelFormat.Depth32Float_Stencil8;
		metalView.enableSetNeedsDisplay = false
		metalView.paused = false
        vd.setMTLViewProperties(metalView)
		metalView.delegate = vd
        metalView.preferredFramesPerSecond = 30
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}

@objc class ViewDelegate : NSObject, MTKViewDelegate {
	
	let asChart : Bool
	
	var engine : LineEngine
    var semaphore : dispatch_semaphore_t
    
	var series : OrderedSeries
    var line : Line
    var projection : UniformProjection
	
	override init() {
		asChart = true
		let res = DeviceResource.defaultResource()
		engine = LineEngine(resource:res)
		semaphore = dispatch_semaphore_create(2)
		series = OrderedSeries(resource:res, vertexCapacity:(1<<13))
		line = OrderedPolyLine(resource:res, orderedSeries:series, engine:engine)
		projection = UniformProjection(resource:res)
		if(asChart) {
			line.setSampleData()
			series.info.count = 5
			series.info.offset = 0
		}
	}
    
    func setMTLViewProperties(view: MTKView) {
        let size : CGSize = view.bounds.size
        projection.setPhysicalSize(size)
        projection.sampleCount = UInt(view.sampleCount)
        projection.colorPixelFormat = view.colorPixelFormat
    }
    
    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
//        projection.setPhysicalSize(size) // ios 9 beta 5 でシグニチャが変更され、sizeもbounds.sizeからピクセル単位になった。
        projection.setPixelSize(size)
        projection.setValueScale(CGSizeMake(1, size.height/size.width))
    }
	
	@objc func drawInMTKView(view: MTKView) {
		
        let size : CGSize = view.bounds.size
		let asChart = true
        
		
		if( asChart ) {
        
			let exp : UInt = 8
			let countDraw : UInt = 1 << exp
			let countAdd : UInt = 1 << (0)
			
			line.setSampleAttributes()
			line.appendSampleData(countAdd)
			
			if( series.info.count >= series.vertices.capacity ) {
				series.info.offset += countAdd;
			} else {
				series.info.count += countAdd
			}
			
			projection.setValueScale(CGSizeMake(CGFloat(countDraw/2), size.height/size.width * 5))
			let count = max(0, Int(series.info.offset + series.info.count) - Int(countDraw/4))
			let ox = Float(count)
			projection.setOrigin(CGPointMake(-2 * CGFloat(ox/Float(countDraw)), 0))
			
		}
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        
		guard let pass : MTLRenderPassDescriptor = view.currentRenderPassDescriptor else { return }
		let queue = DeviceResource.defaultResource().queue
		let buffer = queue.commandBuffer()
		
        line.encodeTo(buffer, renderPass: pass, projection: projection)
        
        buffer.addCompletedHandler { (buffer) -> Void in
            dispatch_semaphore_signal(semaphore)
        }
        
        guard let drawable : MTLDrawable = view.currentDrawable else { return }
		buffer.presentDrawable(drawable)
        
        buffer.commit()
	}
	
}
