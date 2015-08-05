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
        metalView.clearColor = MTLClearColorMake(0.5,0.5,0.5,1)
        metalView.clearDepth = 0
		metalView.colorPixelFormat = MTLPixelFormat.BGRA8Unorm
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
	
	var engine : LineEngine = LineEngine(resource: DeviceResource.defaultResource(), bufferCapacity: 5)
    var semaphore : dispatch_semaphore_t = dispatch_semaphore_create(1)
	
	@objc func view(view: MTKView, willLayoutWithSize size: CGSize) {
	}
	
	@objc func drawInView(view: MTKView) {
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        
		guard let pass : MTLRenderPassDescriptor = view.currentRenderPassDescriptor else { return }
		let queue = DeviceResource.defaultResource().queue
		let buffer = queue.commandBuffer()
		
		engine.encodeTo(buffer, pass:pass, sampleCount:UInt( view.sampleCount ), format:view.colorPixelFormat, size:view.bounds.size)
        
        buffer.addCompletedHandler { (buffer) -> Void in
            dispatch_semaphore_signal(semaphore)
        }
        
        guard let drawable : MTLDrawable = view.currentDrawable else { return }
		buffer.presentDrawable(drawable)
        
        buffer.commit()
	}
	
}
