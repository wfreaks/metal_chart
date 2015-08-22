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
						  restriction:(id<MCInterpreterStateRestriction> _Nullable)restriction
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
		_restriction = restriction;
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
			const CGPoint oldT = _translationCumulative;
			const CGFloat x = oldT.x + (dist * cos(stepped));
			const CGFloat y = oldT.y + (dist * sin(stepped));
			self.translationCumulative = CGPointMake(x, y);
			const CGPoint newT = self.translationCumulative;
			
			if(!CGPointEqualToPoint(oldT, newT)) {
			
				NSArray<id<MCCumulativeInteraction>> *cumulatives = _cumulatives;
				for(id<MCCumulativeInteraction> object in cumulatives) {
					[object didTranslationChange:self];
				}
				
				NSArray<id<MCDifferenceInteraction>> *differences = _differences;
				if(differences) {
					const CGPoint cumDiff = CGPointMake(newT.x-oldT.x, newT.y-oldT.y);
					for(id<MCDifferenceInteraction> object in differences) {
						[object interpreter:self didTranslationChanged:cumDiff];
					}
				}
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
				const CGSize oldScale = _scaleCumulative;
				const CGFloat width = oldScale.width + (scaleDiff * cos(stepped));
				const CGFloat height = oldScale.height + (scaleDiff * sin(stepped));
				self.scaleCumulative = CGSizeMake(width, height);
				const CGSize newScale = _scaleCumulative;
				
				if(CGSizeEqualToSize(oldScale, newScale)) {
				
					NSArray<id<MCCumulativeInteraction>> *cumulatives = _cumulatives;
					for(id<MCCumulativeInteraction> object in cumulatives) {
						[object didScaleChange:self];
					}

					NSArray<id<MCDifferenceInteraction>> *differences = _differences;
					if(_differences.count > 0) {
						const CGSize cumDiff = CGSizeMake(newScale.width-oldScale.width, newScale.height-oldScale.height);
						for(id<MCDifferenceInteraction> object in differences) {
							[object interpreter:self didScaleChanged:cumDiff];
						}
					}
				}
			}
		}
	}
}

- (void)setTranslationCumulative:(CGPoint)translationCumulative
{
	[_restriction interpreter:self willTranslationChange:&translationCumulative];
	_translationCumulative = translationCumulative;
}

- (void)setScaleCumulative:(CGSize)scaleCumulative
{
	[_restriction interpreter:self willScaleChange:&scaleCumulative];
	_scaleCumulative = scaleCumulative;
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

