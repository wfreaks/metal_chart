//
//  MCInteractive.m
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/22.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "MCInteractive.h"
#import "NSArray+Utility.h"

@interface MCGestureInterpreter()

@property (assign, nonatomic) CGPoint currentTranslation;
@property (assign, nonatomic) CGFloat currentScale;

- (void)handlePanning:(UIPanGestureRecognizer *)recognizer;
- (void)handlePinching:(UIPinchGestureRecognizer *)reconginer;

@end

@implementation MCGestureInterpreter

- (instancetype)initWithPanRecognizer:(UIPanGestureRecognizer *)pan
					  pinchRecognizer:(UIPinchGestureRecognizer *)pinch
{
	self = [self init];
	if(self) {
		_interactives = [NSArray array];
		_orientationStep = 45;
		self.panRecognizer = pan;
		self.pinchRecognizer = pinch;
	}
	return self;
}

- (void)handlePanning:(UIPanGestureRecognizer *)recognizer
{
	const UIGestureRecognizerState state = recognizer.state;
	if(state == UIGestureRecognizerStateBegan) {
		_currentTranslation = [recognizer translationInView:recognizer.view];
	} else if (state == UIGestureRecognizerStateChanged) {
		const CGPoint t = [recognizer translationInView:recognizer.view];
		const CGPoint diff = {t.x - _currentTranslation.x, t.y - _currentTranslation.y};
		_currentTranslation = t;
		
		const CGFloat dist = sqrt((diff.x*diff.x) + (diff.y*diff.y));
		if(dist > 0 && !isnan(dist)) {
			const CGFloat orientation = atan2(diff.x, diff.y) * 180 / M_PI;
			const CGFloat stepped = (_orientationStep > 0) ? round(orientation/_orientationStep) * _orientationStep : orientation;
			
			NSArray<id<MCInteractive>> *ar = _interactives;
			for(id<MCInteractive> object in ar) {
				[object translationChanged:dist orientation:stepped];
			}
		}
	}
}

- (void)handlePinching:(UIPinchGestureRecognizer *)reconginer
{
	const UIGestureRecognizerState state = reconginer.state;
	if(state == UIGestureRecognizerStateBegan) {
		_currentScale = reconginer.scale;
	} else if (state == UIGestureRecognizerStateChanged) {
		const CGFloat scale = reconginer.scale;
		const CGFloat scaleDiff = scale - _currentScale;
		_currentScale = scale;
		if(reconginer.numberOfTouches == 2) {
			UIView *v = reconginer.view;
			const CGPoint a = [reconginer locationOfTouch:0 inView:v];
			const CGPoint b = [reconginer locationOfTouch:1 inView:v];
			const CGPoint diff = {b.x-a.x, b.y-a.y};
			const CGFloat dist = (diff.x*diff.x) + (diff.y*diff.y);
			if(dist > 0 && !isnan(dist)) {
				const CGFloat orientation = atan2(diff.x, diff.y) * 180 / M_PI;
				const CGFloat stepped = (_orientationStep > 0) ? round(orientation/_orientationStep) * _orientationStep : orientation;
				
				NSArray<id<MCInteractive>> *ar = _interactives;
				for(id<MCInteractive> object in ar) {
					[object scaleChanged:scaleDiff orientation:stepped];
				}
			}
		}
	}
}

- (void)dealloc
{
	self.panRecognizer = nil;
	self.pinchRecognizer = nil;
}

- (void)addInteractive:(id<MCInteractive>)object
{
	@synchronized(self) {
		_interactives = [_interactives arrayByAddingObjectIfNotExists:object];
	}
}

- (void)removeInteractive:(id<MCInteractive>)object
{
	@synchronized(self) {
		_interactives = [_interactives arrayByRemovingObject:object];
	}
}

- (void)setPanRecognizer:(UIPanGestureRecognizer *)panRecognizer
{
	@synchronized(self) {
		if(_panRecognizer != panRecognizer) {
			if(_panRecognizer) {
				[_panRecognizer removeTarget:self action:@selector(handlePanning:)];
			}
			if(panRecognizer) {
				[panRecognizer addTarget:self action:@selector(handlePanning:)];
			}
		}
	}
}

- (void)setPinchRecognizer:(UIPinchGestureRecognizer *)pinchRecognizer
{
	@synchronized(self) {
		if(_pinchRecognizer != pinchRecognizer) {
			if(_pinchRecognizer) {
				[_pinchRecognizer removeTarget:self action:@selector(handlePinching:)];
			}
			if(pinchRecognizer) {
				[pinchRecognizer addTarget:self action:@selector(handlePinching:)];
			}
		}
	}
}


@end

