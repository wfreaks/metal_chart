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
	
	var isLineInitialized = false
	
	var engine : LineEngine = LineEngine(resource: DeviceResource.defaultResource())
    var semaphore : dispatch_semaphore_t = dispatch_semaphore_create(2)
    
    var line : Line = OrderedPolyLine(resource: DeviceResource.defaultResource(), vertexCapacity:(1<<13) );
    var projection : UniformProjection = UniformProjection(resource: DeviceResource.defaultResource())
    
    func setMTLViewProperties(view: MTKView) {
        let size : CGSize = view.bounds.size
        projection.setPhysicalSize(size)
        projection.sampleCount = UInt(view.sampleCount)
        projection.colorPixelFormat = view.colorPixelFormat
    }
    
    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
        projection.setPhysicalSize(size)
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
			
			if( line.info.count >= line.vertices.capacity ) {
				line.info.offset += countAdd;
			} else {
				line.info.count += countAdd
			}
			
			projection.setValueScale(CGSizeMake(CGFloat(countDraw/2), size.height/size.width * 5))
			let count = max(0, Int(line.info.offset + line.info.count) - Int(countDraw/4))
			let ox = Float(count)
			projection.setOrigin(CGPointMake(-2 * CGFloat(ox/Float(countDraw)), 0))
			
		} else {
			if(!isLineInitialized) {
				projection.setValueScale(CGSizeMake(1, size.height/size.width))
				line.setSampleData()
				isLineInitialized = true
				line.info.count = 5
				line.info.offset = 0
			}
			
		}
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        
		guard let pass : MTLRenderPassDescriptor = view.currentRenderPassDescriptor else { return }
		let queue = DeviceResource.defaultResource().queue
		let buffer = queue.commandBuffer()
		
        line.encodeTo(buffer, renderPass: pass, projection: projection, engine: engine)
        
        buffer.addCompletedHandler { (buffer) -> Void in
            dispatch_semaphore_signal(semaphore)
        }
        
        guard let drawable : MTLDrawable = view.currentDrawable else { return }
		buffer.presentDrawable(drawable)
        
        buffer.commit()
	}
	
}
