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

@property (assign, nonatomic) CGPoint translationCumulative;
@property (assign, nonatomic) CGSize  scaleCumulative;

@property (readonly, nonatomic) NSArray<id<MCDifferenceInteraction>> *differences;
@property (readonly, nonatomic) NSArray<id<MCCumulativeInteraction>> *cumulatives;

- (void)handlePanning:(UIPanGestureRecognizer *)recognizer;
- (void)handlePinching:(UIPinchGestureRecognizer *)reconginer;

@end

@implementation MCGestureInterpreter

@dynamic orientationStepDegree;

- (instancetype)initWithPanRecognizer:(UIPanGestureRecognizer *)pan
					  pinchRecognizer:(UIPinchGestureRecognizer *)pinch
{
	self = [self init];
	if(self) {
		_differences = [NSArray array];
		_cumulatives = [NSArray array];
		_orientationStep = M_PI_4; // 45 degree.
		_scaleCumulative = CGSizeMake(1, 1);
		_translationCumulative = CGPointZero;
		self.panRecognizer = pan;
		self.pinchRecognizer = pinch;
	}
	return self;
}

- (CGFloat)orientationStepDegree { return _orientationStep * 180 / M_PI; }
- (void)setOrientationStepDegree:(CGFloat)degree { _orientationStep = degree * M_PI / 180; }

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
			const CGFloat or_rad = atan2(diff.x, diff.y);
			const CGFloat stepped = (_orientationStep > 0) ? round(or_rad/_orientationStep) * _orientationStep : or_rad;
			_translationCumulative.x += cos(or_rad);
			_translationCumulative.y += sin(or_rad);
			
			NSArray<id<MCDifferenceInteraction>> *differences = _differences;
			NSArray<id<MCCumulativeInteraction>> *cumulatives = _cumulatives;
			for(id<MCDifferenceInteraction> object in differences) {
				[object translationChanged:dist orientation:stepped];
			}
			for(id<MCCumulativeInteraction> object in cumulatives) {
				[object translationChanged:_translationCumulative];
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
				const CGFloat or_rad = atan2(diff.x, diff.y);
				const CGFloat stepped = (_orientationStep > 0) ? round(or_rad/_orientationStep) * _orientationStep : or_rad;
				_scaleCumulative.width += cos(or_rad);
				_scaleCumulative.height += sin(or_rad);
				
				NSArray<id<MCDifferenceInteraction>> *differences = _differences;
				NSArray<id<MCCumulativeInteraction>> *cumulatives = _cumulatives;
				for(id<MCDifferenceInteraction> object in differences) {
					[object scaleChanged:scaleDiff orientation:stepped];
				}
				for(id<MCCumulativeInteraction> object in cumulatives) {
					[object scaleChanged:_scaleCumulative];
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

- (void)addDifference:(id<MCDifferenceInteraction>)object
{
	@synchronized(self) {
		_differences = [_differences arrayByAddingObjectIfNotExists:object];
	}
}

- (void)removeDifference:(id<MCDifferenceInteraction>)object
{
	@synchronized(self) {
		_differences = [_differences arrayByRemovingObject:object];
	}
}

- (void)addCumulative:(id<MCDifferenceInteraction>)object
{
	@synchronized(self) {
		_cumulatives = [_cumulatives arrayByAddingObjectIfNotExists:object];
	}
}

- (void)removeCumulative:(id<MCDifferenceInteraction>)object
{
	@synchronized(self) {
		_cumulatives = [_cumulatives arrayByRemovingObject:object];
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

- (void)resetCumulativeStates
{
	_translationCumulative = CGPointZero;
	_scaleCumulative = CGSizeMake(1, 1);
}

@end

