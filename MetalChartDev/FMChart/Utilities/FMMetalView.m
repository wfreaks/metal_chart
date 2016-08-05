//
//  FMMetalView.m
//  FMChart
//
//  Created by Keisuke Mori on 2015/10/30.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "FMMetalView.h"
#import <QuartzCore/QuartzCore.h>
#import <Metal/Metal.h>

@interface _FMMetalView()

@property (nonatomic, readonly, weak) CAMetalLayer *	metalLayer;
@property (nonatomic, readonly) CADisplayLink *		 display;
@property (nonatomic, readonly) CGFloat				 screenScale;

@property (nonatomic, readonly) NSRunLoop *		  runloop;

@property (nonatomic, readwrite) id<CAMetalDrawable> currentDrawable;
@property (nonatomic, readwrite) MTLRenderPassDescriptor *currentRenderPassDescriptor;
@property (nonatomic, readwrite) id<MTLTexture>	  depthStencilTexture;
@property (nonatomic, readwrite) id<MTLTexture>	  multisampleColorTexture;

@property (nonatomic, assign) BOOL needsRedraw;

@end

@implementation _FMMetalView

+ (Class)layerClass
{
	return [CAMetalLayer class];
}

- (CAMetalLayer *)metalLayer { return (CAMetalLayer *)self.layer; }

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if(self) {
		[self _postInit];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];
}

- (instancetype)initWithFrame:(CGRect)frame device:(id<MTLDevice>)device
{
	self = [super initWithFrame:frame];
	if(self) {
		_device = device;
		[self _postInit];
	}
	return self;
}

- (void)_postInit
{
	_needsRedraw = YES;
	_screenScale = [[UIScreen mainScreen] scale];
	_runloop = [NSRunLoop mainRunLoop];
	_sampleCount = 1;
	_autoResizeDrawable = YES;
}

- (void)setPreferredFramesPerSecond:(NSInteger)fps
{
	_preferredFramesPerSecond = fps;
	if(fps > 0) {
		_paused = NO;
		_enableSetNeedsDisplay = NO;
	}
	[self _updateDisplayLink];
}

- (void)setPaused:(BOOL)paused
{
	_paused = paused;
	[self _updateDisplayLink];
}

- (void)setEnableSetNeedsDisplay:(BOOL)enableSetNeedsDisplay
{
	_enableSetNeedsDisplay = enableSetNeedsDisplay;
	[self _updateDisplayLink];
}

- (void)_updateDisplayLink
{
	if(_display) {
		const BOOL enabled = (_paused && _enableSetNeedsDisplay);
		const NSInteger fps = (enabled) ? 60 : _preferredFramesPerSecond;
		const CFTimeInterval duration = _display.duration;
		const CFTimeInterval spf = (fps > 0) ? 1.0/fps : 0;
		_display.paused = self.paused & (spf <= 0);
		
		if(spf > 0) {
			const NSInteger n = ceil(spf / (duration > 0 ? duration : 0.1666));
			_display.frameInterval = n;
		}
	}
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
	[super willMoveToWindow:newWindow];
	_screenScale = [newWindow.screen scale];
	if(newWindow) {
		_display = [CADisplayLink displayLinkWithTarget:self selector:@selector(_refreshView)];
		[_display addToRunLoop:_runloop forMode:NSRunLoopCommonModes];
		[self _updateDisplayLink];
	} else {
		[_display invalidate];
		_display = nil;
	}
}

- (CGSize)drawableSize {return self.metalLayer.drawableSize; }

- (void)setDrawableSize:(CGSize)drawableSize
{
	const CGSize prev = self.metalLayer.drawableSize;
	if(!CGSizeEqualToSize(drawableSize, prev)) {
		self.metalLayer.drawableSize = drawableSize;
		drawableSize = self.metalLayer.drawableSize;
		_depthStencilTexture = nil;
		_multisampleColorTexture = nil;
		if(_enableSetNeedsDisplay) {
			[self setNeedsDisplay];
		}
	}
	[_delegate mtkView:(FMMetalView*)self drawableSizeWillChange:drawableSize];
}

- (BOOL)frameBufferOnly { return self.metalLayer.framebufferOnly; }
- (void)setFrameBufferOnly:(BOOL)frameBufferOnly {
	self.metalLayer.framebufferOnly = frameBufferOnly;
}

- (BOOL)presentsWithTransaction { return self.metalLayer.presentsWithTransaction; }
- (void)setPresentsWithTransaction:(BOOL)presentsWithTransaction {
	self.metalLayer.presentsWithTransaction = presentsWithTransaction;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	if(_autoResizeDrawable) {
		const CGSize size = self.metalLayer.bounds.size;
		self.drawableSize = CGSizeMake(size.width * _screenScale, size.height * _screenScale);
	}
}

- (void)_refreshView
{
	[self draw];
}

- (void)draw
{
	const BOOL needsRedraw = _needsRedraw;
	const BOOL enableDisplay = _enableSetNeedsDisplay;
	if(needsRedraw | (!enableDisplay)) {
		_needsRedraw = NO;
		id<FMMetalViewDelegate> delegate = _delegate;
		if(delegate && self.device) {
			[delegate drawInMTKView:(FMMetalView*)self];
			_currentDrawable = nil;
			_currentRenderPassDescriptor = nil;
		} else {
			[self drawRect:self.bounds];
		}
	} else {
		_needsRedraw = NO;
	}
}

- (void)setNeedsDisplay
{
	if(self.enableSetNeedsDisplay) {
		_needsRedraw = YES;
	}
}

- (MTLPixelFormat)colorPixelFormat { return self.metalLayer.pixelFormat; }
- (void)setColorPixelFormat:(MTLPixelFormat)colorPixelFormat
{
	if(self.metalLayer.pixelFormat != colorPixelFormat) {
		self.metalLayer.pixelFormat = colorPixelFormat;
		_multisampleColorTexture = nil;
	}
}

- (id<CAMetalDrawable>)currentDrawable
{
	if(_currentDrawable == nil) {
		_currentDrawable = self.metalLayer.nextDrawable;
	}
	return _currentDrawable;
}

- (MTLRenderPassDescriptor *)currentRenderPassDescriptor
{
	if(_currentRenderPassDescriptor == nil) {
		id<CAMetalDrawable> drawable = self.currentDrawable;
		if(drawable) {
			MTLRenderPassDescriptor *pass = [MTLRenderPassDescriptor renderPassDescriptor];
			MTLRenderPassColorAttachmentDescriptor *color = pass.colorAttachments[0];
			color.loadAction = MTLLoadActionClear;
			color.clearColor = _clearColor;
			
			id<MTLTexture> tex = [drawable texture];
			id<MTLTexture> msaa = self.multisampleColorTexture;
			const BOOL useMsaa = (msaa != nil);
			color.texture = (useMsaa) ? msaa : tex;
			color.resolveTexture = (useMsaa) ? tex : nil;
			color.storeAction = (useMsaa) ? MTLStoreActionMultisampleResolve : MTLStoreActionStore;
			
			id<MTLTexture> depthTex = self.depthStencilTexture;
			if(depthTex) {
				pass.depthAttachment.texture = depthTex;
				pass.depthAttachment.loadAction = MTLLoadActionClear;
				pass.depthAttachment.clearDepth = _clearDepth;
				MTLPixelFormat depthFormat = _depthStencilPixelFormat;
				if(depthFormat == MTLPixelFormatDepth32Float_Stencil8) {
					pass.stencilAttachment.texture = depthTex;
					pass.stencilAttachment.loadAction = MTLLoadActionClear;
					pass.stencilAttachment.clearStencil = _clearStencil;
				}
			}
			
			_currentRenderPassDescriptor = pass;
		}
	}
	return _currentRenderPassDescriptor;
}

- (void)setDepthStencilPixelFormat:(MTLPixelFormat)depthStencilPixelFormat
{
	if(_depthStencilPixelFormat != depthStencilPixelFormat) {
		_depthStencilPixelFormat = depthStencilPixelFormat;
		_depthStencilTexture = nil;
	}
}

- (void)prepareDepthStencilTexture
{
	const MTLPixelFormat format = _depthStencilPixelFormat;
	const BOOL isValid = (format == MTLPixelFormatDepth32Float || format == MTLPixelFormatDepth32Float_Stencil8);
	const NSUInteger count = _sampleCount;
	if(isValid) {
		const CGSize size = self.metalLayer.drawableSize;
		MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:format
																						width:size.width
																					   height:size.height
																					mipmapped:NO];
		if(count > 1) {
			desc.textureType = MTLTextureType2DMultisample;
			desc.sampleCount = _sampleCount;
		}
		_depthStencilTexture = [_device newTextureWithDescriptor:desc];
	}
}

- (id<MTLTexture>)depthStencilTexture
{
	if(_depthStencilTexture == nil) {
		[self prepareDepthStencilTexture];
	}
	return _depthStencilTexture;
}

- (void)setSampleCount:(NSUInteger)sampleCount
{
	if(_sampleCount != sampleCount) {
		_sampleCount = sampleCount;
		_multisampleColorTexture = nil;
		_depthStencilTexture = nil;
	}
}

- (void)prepareMultisamplingColorTexture
{
	const MTLPixelFormat format = self.colorPixelFormat;
	const BOOL isValid = (format == MTLPixelFormatBGRA8Unorm		||
						  format == MTLPixelFormatBGRA8Unorm_sRGB   ||
						  format == MTLPixelFormatRGBA16Float
						  );
	const NSUInteger count = _sampleCount;
	if(isValid && count > 1) {
		const CGSize size = self.metalLayer.drawableSize;
		MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:self.colorPixelFormat
																						width:size.width
																					   height:size.height
																					mipmapped:NO];
		desc.textureType = MTLTextureType2DMultisample;
		desc.sampleCount = count;
		
		_multisampleColorTexture = [_device newTextureWithDescriptor:desc];
	}
}

- (id<MTLTexture>)multisampleColorTexture
{
	if(_depthStencilTexture == nil) {
		[self prepareMultisamplingColorTexture];
	}
	return _multisampleColorTexture;
}

- (void)releaseDrawables
{
	_currentDrawable = nil;
	_depthStencilTexture = nil;
	_multisampleColorTexture = nil;
}

@end


@implementation FMMetalView

@end

