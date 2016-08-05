//
//  FMMetalView.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/10/30.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Metal/MTLTypes.h>
#import <Metal/MTLPixelFormat.h>
#import <Metal/MTLRenderPass.h>
#import "chart_common.h"

@class FMMetalView;
@protocol CAMetalDrawable;

/**
 * FMMetalViewDelegate protocol mimicks MTKViewDelegate (this interface was first introduced to allow framework users to 
 * support ios 8 without code midifcation.)
 * This protocol SHOULD BE referred to using type alias 'FMMetalViewDelegate'.
 */

#ifdef USE_METALKIT

#import <MetalKit/MetalKit.h>

@protocol FMMetalViewDelegate <MTKViewDelegate>

@end

#else

@protocol FMMetalViewDelegate

- (void)mtkView:(FMMetalView *)metalView drawableSizeWillChange:(CGSize)size;

- (void)drawInMTKView:(FMMetalView *)metalView;

@end

#endif

/**
 * FMMetalView class was (initially) written to mimic MTKView.
 * This class SHOULD NOT be reffered to directory (use FMMetalView type alias, which is declared in Headers/iosX/chart_common.h).
 * The only exception to above statement is Storyboard/Xib files (type alias is not usable in those files).
 *
 * Its interface is almost identical to MTKView (as of iOS9), but its behavior is slightly different from original.
 * (FMMetalView calls delegate's draw method at constant timing even when set to event-driven mode, i.e. draw method never get called more than  60 per sec.)
 */
@interface _FMMetalView : UIView

@property (weak, nonatomic) id<FMMetalViewDelegate> delegate;

@property (nonatomic) id<MTLDevice> device;

@property (nonatomic) MTLClearColor	 clearColor;
@property (nonatomic) double			clearDepth;
@property (nonatomic) uint32_t		  clearStencil;
@property (nonatomic) MTLPixelFormat	colorPixelFormat;
@property (nonatomic) MTLPixelFormat	depthStencilPixelFormat;
@property (nonatomic) NSUInteger		sampleCount;

@property (nonatomic) NSInteger		 preferredFramesPerSecond;
@property (nonatomic) BOOL			  paused;
@property (nonatomic) BOOL			  enableSetNeedsDisplay;

@property (nonatomic) BOOL			  autoResizeDrawable;
@property (nonatomic) CGSize			drawableSize;
@property (nonatomic) BOOL			  frameBufferOnly;
@property (nonatomic) BOOL			  presentsWithTransaction;

@property (nonatomic, readonly) id<CAMetalDrawable> currentDrawable;

@property (nonatomic, readonly) MTLRenderPassDescriptor *currentRenderPassDescriptor;
@property (nonatomic, readonly) id<MTLTexture>	  depthStencilTexture;
@property (nonatomic, readonly) id<MTLTexture>	  multisampleColorTexture;

- (void)draw;
- (void)releaseDrawables;

- (instancetype)initWithCoder:(NSCoder *)aDecoder
NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithFrame:(CGRect)frame device:(id<MTLDevice>)device
NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithFrame:(CGRect)frame
UNAVAILABLE_ATTRIBUTE;

@end


#ifdef USE_METALKIT

@interface FMMetalView : MTKView
@endif

#else

@interface FMMetalView : _FMMetalView
@end

#endif
