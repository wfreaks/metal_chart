//
//  FMInteractive.m
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/22.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "common_private.h"
#import "FMInteractive.h"
#import "NSArray+Utility.h"
#import "FMProjectionUpdater.h"
#import "FMAnimator.h"
#import <UIKit/UIGestureRecognizerSubclass.h>


@interface FMInertialState : NSObject

@property (nonatomic, readonly) CGFloat velocity;
@property (nonatomic, readonly) CFAbsoluteTime timestamp;
@property (nonatomic, readonly) CGFloat dampingCoefficent;
@property (nonatomic, readonly) BOOL stationary;
@property (nonatomic) NSTimeInterval maxDuration;

- (instancetype)initWithMaxDuration:(CGFloat)duration
NS_DESIGNATED_INITIALIZER;

- (instancetype)init
UNAVAILABLE_ATTRIBUTE;

- (void)halt:(CFAbsoluteTime)time;
- (CGFloat)updateWithDelta:(CGFloat)delta velocity:(CGFloat)velocity time:(CFAbsoluteTime)time destination:(CGFloat)destination;
- (CGFloat)updateWithTime:(CFAbsoluteTime)time destination:(CGFloat)destination;

@end
@implementation FMInertialState

static const CGFloat VEC_THRESHOLD = 1;
static const CGFloat MIN_DECAY = 4;
static const CGFloat DEST_THREASHOLD = 0.2;

- (instancetype)initWithMaxDuration:(CGFloat)duration
{
	self = [super init];
	if(self) {
		_maxDuration = duration;
		_stationary = YES;
	}
	return self;
}

- (void)halt:(CFAbsoluteTime)time
{
	@synchronized(self) {
		_velocity = 0;
		_timestamp = time;
		_dampingCoefficent = 0;
	}
}

- (CGFloat)updateWithDelta:(CGFloat)delta velocity:(CGFloat)velocity time:(CFAbsoluteTime)time destination:(CGFloat)dest
{
	@synchronized(self) {
		CGFloat d = delta;
		const NSTimeInterval timeDiff = time - _timestamp;
		_timestamp = time;
		if(timeDiff > 0) {
			const CGFloat absDest = fabs(dest);
			if(absDest > 0 && delta * dest <= 0) {
				const CGFloat coef = exp(-(absDest/50));
				_velocity = velocity * coef;
				d *= coef;
			} else {
				_velocity = velocity;
			}
			const CGFloat k = log(fabs(_velocity / VEC_THRESHOLD)) / _maxDuration;
			_dampingCoefficent = MAX(MIN_DECAY, k);
			_stationary = (_velocity == 0 && dest == 0);
//			DebugLog(@"velocity = %.1f", _velocity);
		}
		return d;
	}
}

- (CGFloat)updateWithTime:(CFAbsoluteTime)time destination:(CGFloat)dest
{
	@synchronized(self) {
		CGFloat displacement = 0;
		const NSTimeInterval diff = time - _timestamp;
		_timestamp = time;
		const CGFloat oldm = _velocity;
		if(diff > 0) {
			CGFloat v = oldm;
			if(dest != 0) {
				const CGFloat x = (oldm / _dampingCoefficent); // 外力なしで静止まで減衰するまでの移動量.
				v += (dest - x) * diff * 100;
			}
			if (oldm != 0 || v != 0 || dest != 0) {
				const CGFloat newm = (v * exp(-(_dampingCoefficent * diff)));
				const CGFloat absDest = fabs(dest);
				const CGFloat absm = fabs(newm);
				if(absm < VEC_THRESHOLD && (0 < absDest && absDest < DEST_THREASHOLD)) {
					displacement = dest;
					_velocity = 0;
				} else {
					displacement = (newm + oldm) * diff / 2;
					_velocity = (absm > VEC_THRESHOLD) ? newm : 0;
				}
			}
			_stationary = (_velocity == 0 && displacement == 0);
//			DebugLog(@"velocity = %.1f", _velocity);
		}
		return displacement;
	}
}

@end




@interface FMGestureDispatcher() <FMPanGestureRecognizerDelegate>

@property (readonly, nonatomic) CGPoint currentTranslation;
@property (readonly, nonatomic) CGFloat currentScale;
@property (readonly, nonatomic) NSOrderedSet<id<FMPanGestureListener>>* xPanListener;
@property (readonly, nonatomic) NSOrderedSet<id<FMPanGestureListener>>* yPanListener;
@property (readonly, nonatomic) NSOrderedSet<id<FMScaleGestureListener>>* xScaleListener;
@property (readonly, nonatomic) NSOrderedSet<id<FMScaleGestureListener>>* yScaleListener;

- (void)handlePanning:(FMPanGestureRecognizer *)recognizer;
- (void)handlePinching:(UIPinchGestureRecognizer *)reconginer;

@end
@implementation FMGestureDispatcher

- (instancetype)initWithPanRecognizer:(FMPanGestureRecognizer *)pan
					  pinchRecognizer:(UIPinchGestureRecognizer *)pinch
{
	self = [super init];
	if(self) {
		self.panRecognizer = pan;
		self.pinchRecognizer = pinch;
		[self removeAllListeners];
	}
	return self;
}

- (void)didBeginTouchesInRecognizer:(FMPanGestureRecognizer *)recognizer
{
	if(recognizer == self.panRecognizer) {
		const CFAbsoluteTime time = CFAbsoluteTimeGetCurrent();
		[self notifyPan:CGPointZero velocity:CGPointZero time:time event:FMGestureEventBegin];
	}
}

- (void)handlePanning:(FMPanGestureRecognizer *)recognizer
{
	const UIGestureRecognizerState state = recognizer.state;
	const CFAbsoluteTime time = CFAbsoluteTimeGetCurrent();
	const BOOL began = (state == UIGestureRecognizerStateBegan);
	const BOOL progress = (state == UIGestureRecognizerStateChanged);
	const BOOL end = (state == UIGestureRecognizerStateEnded);
	const CGPoint t = [recognizer translationInView:recognizer.view];
	const CGPoint v = [recognizer velocityInView:recognizer.view];
	if(began) {
		_currentTranslation = t;
	} else if (progress || end) {
		const CGPoint delta = CGPointMake(t.x - _currentTranslation.x, t.y - _currentTranslation.y);
		_currentTranslation = t;
		// window座標とグラフの座標ではy軸の向きが違う。この時点でyの値を反転させておく.
		const FMGestureEvent e =  (end) ? FMGestureEventEnd : FMGestureEventProgress;
		[self notifyPan:delta velocity:v time:time event:e];
	} else {
		
	}
}

- (void)notifyPan:(const CGPoint)delta velocity:(CGPoint)velocity time:(CFAbsoluteTime)timestamp event:(FMGestureEvent)event
{
	for(id<FMPanGestureListener> l in _xPanListener) {
		[l dispatcher:self pan:delta.x velocity:velocity.x timestamp:timestamp event:event];
	}
	for(id<FMPanGestureListener> l in _yPanListener) {
		[l dispatcher:self pan:delta.y velocity:velocity.y timestamp:timestamp event:event];
	}
}

- (void)handlePinching:(UIPinchGestureRecognizer *)recognizer
{
	const UIGestureRecognizerState state = recognizer.state;
	const CFAbsoluteTime time = CFAbsoluteTimeGetCurrent();
	if(state == UIGestureRecognizerStateBegan) {
		_currentScale = recognizer.scale;
	} else if (state == UIGestureRecognizerStateChanged) {
		const CGFloat scale = recognizer.scale;
		const CGFloat scaleDiff = (scale / _currentScale) - 1; // -1よりは大きい.
		_currentScale = scale;
		if(recognizer.numberOfTouches == 2) {
			UIView *v = recognizer.view;
			const CGPoint a = [recognizer locationOfTouch:0 inView:v];
			const CGPoint b = [recognizer locationOfTouch:1 inView:v];
			// a,bと指の対応関係は実行時に変わるが、すでにscaleが取れている以上、右側の指が上だろうが下だろうが結果は変わらない.
			const CGPoint diff = {fabs(b.x-a.x), fabs(b.y-a.y)};
			const CGFloat dist = (diff.x*diff.x) + (diff.y*diff.y);
			if(dist > 0 && !isnan(dist)) {
				const CGFloat or_rad = atan2(diff.y, diff.x);
				const CGFloat cosine = cos(or_rad), sine = sin(or_rad);
				const CGFloat dw = (1 + (scaleDiff * cosine));
				const CGFloat dh = (1 + (scaleDiff * sine));
				const CGFloat vec = recognizer.velocity;
				const CGPoint velocity = CGPointMake(vec * cosine, vec * sine);
				DebugLog(@"scale : %.1f, velocity : %.1f", recognizer.scale, recognizer.velocity);
				[self notifyScale:CGPointMake(dw, dh) velocity:velocity timestamp:time event:FMGestureEventEnd];
			}
		}
	}
}

- (void)notifyScale:(CGPoint)scale velocity:(CGPoint)velocity timestamp:(CFAbsoluteTime)timestamp event:(FMGestureEvent)event
{
	for(id<FMScaleGestureListener> l in _xScaleListener) {
		[l dispatcher:self scale:scale.x velocity:velocity.x timestamp:timestamp event:event];
	}
	for(id<FMScaleGestureListener> l in _yScaleListener) {
		[l dispatcher:self scale:scale.y velocity:velocity.y timestamp:timestamp event:event];
	}
}

- (void)addPanListener:(id<FMPanGestureListener>)listener orientation:(FMDimOrientation)orientation
{
	if(orientation == FMDimOrientationHorizontal) {
		_xPanListener = [_xPanListener orderedSetByAddingObject:listener];
	} else {
		_yPanListener = [_yPanListener orderedSetByAddingObject:listener];
	}
}

- (void)removeAllListeners
{
	_xPanListener = [NSOrderedSet orderedSet];
	_yPanListener = [NSOrderedSet orderedSet];
	_xScaleListener = [NSOrderedSet orderedSet];
	_yScaleListener = [NSOrderedSet orderedSet];
}

- (void)addScaleListener:(id<FMScaleGestureListener>)listener orientation:(FMDimOrientation)orientation
{
	if(orientation == FMDimOrientationHorizontal) {
		_xScaleListener = [_xScaleListener orderedSetByAddingObject:listener];
	} else {
		_yScaleListener = [_yScaleListener orderedSetByAddingObject:listener];
	}
}

- (void)dealloc
{
	self.panRecognizer = nil;
	self.pinchRecognizer = nil;
}

- (void)setPanRecognizer:(FMPanGestureRecognizer *)panRecognizer
{
	@synchronized(self) {
		if(_panRecognizer != panRecognizer) {
			if(_panRecognizer) {
				[_panRecognizer removeTarget:self action:@selector(handlePanning:)];
				if(_panRecognizer.recognizerDelegate == self) _panRecognizer.recognizerDelegate = nil;
			}
			if(panRecognizer) {
				[panRecognizer addTarget:self action:@selector(handlePanning:)];
				panRecognizer.recognizerDelegate = self;
			}
			_panRecognizer = panRecognizer;
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
			_pinchRecognizer = pinchRecognizer;
		}
	}
}

@end


@interface FMScaledWindowLength()

@end
@implementation FMScaledWindowLength

- (instancetype)initWithMinScale:(CGFloat)min maxScale:(CGFloat)max defaultScale:(CGFloat)def
{
	self = [super init];
	if(self) {
		_minScale = min;
		_maxScale = max;
		_defaultScale = def;
		_currentScale = def;
	}
	return self;
}

- (CGFloat)lengthForViewPort:(CGFloat)viewPort dataRange:(CGFloat)length
{
	return viewPort * _currentScale;
}

- (void)dispatcher:(FMGestureDispatcher *)dispatcher scale:(CGFloat)factor velocity:(CGFloat)velocity timestamp:(CFAbsoluteTime)timestamp event:(FMGestureEvent)event
{
	[self _updateWithFactor:factor timestamp:timestamp useFactor:YES];
}

- (void)_updateWithFactor:(CGFloat)factor timestamp:(CFAbsoluteTime)timestamp useFactor:(BOOL)useFactor
{
	const CGFloat _f = 1/factor;
	const CGFloat modifiedScale = _currentScale * _f;
	const CGFloat cappedScale = MIN(_maxScale, MAX(_minScale, modifiedScale));
	_currentScale *= cappedScale;
	
	[_updater updateTarget];
	[_view setNeedsDisplay];
}

- (void)reset
{
	_currentScale = _defaultScale;
}

@end




@interface FMAnchoredWindowPosition() <FMAnimation>

@property (nonatomic, readonly) CGFloat minAnchorValue;
@property (nonatomic, readonly) CGFloat maxAnchorValue;
@property (nonatomic, readonly) FMInertialState *state;
@property (nonatomic) BOOL touchInProgress;

@end
@implementation FMAnchoredWindowPosition

- (instancetype)initWithAnchor:(CGFloat)anchor
				  windowLength:(FMScaledWindowLength * _Nonnull)length
			  valueInitializer:(FMWindowPositionBlock _Nonnull)initializer
{
	self = [super init];
	if(self) {
		_anchor = anchor;
		_valueInitializer = initializer;
		_currentValue = 0;
		_invalidated = YES;
		_length = length;
		_state = [[FMInertialState alloc] initWithMaxDuration:2];
	}
	return self;
}

- (instancetype)initWithAnchor:(CGFloat)anchor
				  windowLength:(FMScaledWindowLength *)length
			   defaultPosition:(CGFloat)defaultPosition
{
	return [self initWithAnchor:anchor windowLength:length valueInitializer:^CGFloat(CGFloat min, CGFloat max, CGFloat len) {
		return defaultPosition;
	}];
}

- (CGFloat)positionInRangeWithMin:(CGFloat)minValue max:(CGFloat)maxValue length:(CGFloat)length
{
	const CGFloat margin = (maxValue - minValue) - length;
	const CGFloat offset = length * _anchor;
	_minAnchorValue = minValue + offset;
	_maxAnchorValue = minValue + offset + margin;
	CGFloat pos = 0.5f;
	typeof(_valueInitializer) vi = _valueInitializer;
	if(_invalidated) {
		if(vi) {
			pos = vi(minValue, maxValue, length);
		}
		_currentValue = _minAnchorValue + (margin * pos);
		_invalidated = NO;
	} else {
		pos = (_currentValue - _minAnchorValue) / margin;
	}
	return pos;
}

- (void)dispatcher:(FMGestureDispatcher *)dispatcher pan:(CGFloat)delta velocity:(CGFloat)velocity timestamp:(CFAbsoluteTime)timestamp event:(FMGestureEvent)event
{
	if(event == FMGestureEventBegin) {
		[_state halt:timestamp];
		_touchInProgress = YES;
		return;
	}
	[self _updateWithDelta:-delta velocity:-velocity timestamp:timestamp useDelta:true]; // 符号が逆な事に注意.
	if(event == FMGestureEventEnd) {
		_touchInProgress = NO;
		[dispatcher.animator addAnimation:self];
	}
}

- (void)_updateWithDelta:(CGFloat)delta velocity:(CGFloat)velocity timestamp:(CFAbsoluteTime)timestamp useDelta:(BOOL)useDelta
{
	const CGFloat scale = _length.currentScale;
	const CGFloat excess = (scale > 0) ? ((delta * scale) - (MIN(_maxAnchorValue, MAX(_minAnchorValue, _currentValue + (delta * scale))) - _currentValue)) / scale : 0;
	const CGFloat modifiedDelta = (useDelta) ? [_state updateWithDelta:delta velocity:velocity time:timestamp destination:-excess] : [_state updateWithTime:timestamp  destination:-excess];
	_currentValue += modifiedDelta * scale;
	
	[_view setNeedsDisplay];
	[_updater updateTarget];
}

- (void)reset
{
	[_state halt:CFAbsoluteTimeGetCurrent()];
	_currentValue = 0;
	_invalidated = YES;
}

- (BOOL)requestCancel { return NO; }

- (void)addedToPendingQueueOfAnimator:(FMAnimator *)animator timestamp:(CFAbsoluteTime)timestamp
{
}

- (BOOL)animator:(FMAnimator *)animator shouldStartAnimating:(CFAbsoluteTime)timestamp { return YES; }

- (BOOL)animator:(FMAnimator *)animator animate:(id<MTLCommandBuffer>)buffer timestamp:(CFAbsoluteTime)timestamp
{
	if(_touchInProgress) return YES;
	if(_state.stationary) {
		return YES;
	}
	[self _updateWithDelta:0 velocity:0 timestamp:timestamp useDelta:NO];
	return NO;
}

@end





@implementation FMPanGestureRecognizer

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	[super touchesBegan:touches withEvent:event];
	typeof(self.recognizerDelegate) delegate = self.recognizerDelegate;
	[delegate didBeginTouchesInRecognizer:self];
}

@end


