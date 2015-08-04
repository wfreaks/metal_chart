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
		metalView.colorPixelFormat = MTLPixelFormat.BGRA8Unorm
		metalView.sampleCount = 2
		metalView.enableSetNeedsDisplay = true
		metalView.paused = true
		metalView.delegate = vd
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

}

@objc class ViewDelegate : NSObject, MTKViewDelegate {
	
	var engine : LineEngine = LineEngine(resource: DeviceResource.defaultResource(), bufferCapacity: 1024)
	
	@objc func view(view: MTKView, willLayoutWithSize size: CGSize) {
	}
	
	@objc func drawInView(view: MTKView) {
		guard let pass : MTLRenderPassDescriptor = view.currentRenderPassDescriptor else { return }
		guard let drawable : MTLDrawable = view.currentDrawable else { return }
		let queue = DeviceResource.defaultResource().queue
		let buffer = queue.commandBuffer()
		
		engine.encodeTo(buffer, pass:pass, sampleCount:UInt( view.sampleCount ), format:view.colorPixelFormat)
		
		buffer.presentDrawable(drawable)
	}
	
}
