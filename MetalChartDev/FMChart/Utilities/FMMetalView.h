//
//  FMMetalView.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/10/30.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Metal/MTLTypes.h>
#import <Metal/MTLRenderPass.h>

@class FMMetalView;

@protocol FMMetalViewDelegate

- (void)mtkView:(FMMetalView *)metalView drawableSizeWillChange:(CGSize)size;

- (void)drawInMTKView:(FMMetalView *)metalView;

@end

@interface FMMetalView : UIView

@property (weak, nonatomic) id<FMMetalViewDelegate> delegate;

@property (nonatomic) id<MTLDevice> device;

@property (nonatomic) MTLClearColor     clearColor;
@property (nonatomic) double            clearDepth;
@property (nonatomic) uint32_t          clearStencil;
@property (nonatomic) MTLPixelFormat    colorPixelFormat;
@property (nonatomic) MTLPixelFormat    depthStencilPixelFormat;
@property (nonatomic) NSUInteger        sampleCount;

@property (nonatomic) NSInteger         preferredFramesPerSecond;
@property (nonatomic) BOOL              paused;
@property (nonatomic) BOOL              enableSetNeedsDisplay;

@property (nonatomic) BOOL              autoResizeDrawable;
@property (nonatomic) CGSize            drawableSize;
@property (nonatomic) BOOL              frameBufferOnly;
@property (nonatomic) BOOL              presentsWithTransaction;

@property (nonatomic, readonly) id<CAMetalDrawable> currentDrawable;

@property (nonatomic, readonly) MTLRenderPassDescriptor *currentRenderPassDescriptor;
@property (nonatomic, readonly) id<MTLTexture>      depthStencilTexture;
@property (nonatomic, readonly) id<MTLTexture>      multisampleColorTexture;

- (void)draw;
- (void)releaseDrawables;

- (instancetype)initWithCoder:(NSCoder *)aDecoder
NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithFrame:(CGRect)frame device:(id<MTLDevice>)device
NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithFrame:(CGRect)frame
UNAVAILABLE_ATTRIBUTE;

@end
