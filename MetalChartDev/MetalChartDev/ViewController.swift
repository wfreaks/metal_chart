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
        metalView.sampleCount = 2
        let v : Double = 0.5;
        let alpha : Double = 1;
        metalView.clearColor = MTLClearColorMake(v,v,v,alpha)
        metalView.clearDepth = 0
		metalView.colorPixelFormat = MTLPixelFormat.BGRA8Unorm
        metalView.depthStencilPixelFormat = MTLPixelFormat.Depth32Float_Stencil8;
		metalView.enableSetNeedsDisplay = false
		metalView.paused = false
		metalView.delegate = vd
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}

@objc class ViewDelegate : NSObject, MTKViewDelegate {
	
	var engine : LineEngine = LineEngine(resource: DeviceResource.defaultResource())
    var semaphore : dispatch_semaphore_t = dispatch_semaphore_create(1)
    
    var line : IndexedLine = IndexedLine(resource: DeviceResource.defaultResource(), vertexCapacity:4, indexCapacity: 4);
    var projection : UniformProjection = UniformProjection(resource: DeviceResource.defaultResource())
    
	@objc func view(view: MTKView, willLayoutWithSize size: CGSize) {
	}
	
	@objc func drawInView(view: MTKView) {
        
        line.setSampleData()
        
        projection.setPhysicalSize(view.bounds.size)
        projection.sampleCount = UInt(view.sampleCount)
        projection.colorPixelFormat = view.colorPixelFormat
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        
		guard let pass : MTLRenderPassDescriptor = view.currentRenderPassDescriptor else { return }
		let queue = DeviceResource.defaultResource().queue
		let buffer = queue.commandBuffer()
		
        engine.encodeTo(buffer, pass: pass, indexedLine: line, projection: projection)
        
        buffer.addCompletedHandler { (buffer) -> Void in
            dispatch_semaphore_signal(semaphore)
        }
        
        guard let drawable : MTLDrawable = view.currentDrawable else { return }
		buffer.presentDrawable(drawable)
        
        buffer.commit()
	}
	
}
