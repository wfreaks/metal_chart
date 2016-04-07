//
//  FMInteractive.m
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/22.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "FMInteractive.h"
#import "NSArray+Utility.h"
#import "FMProjectionUpdater.h"
#import "FMRestrictions.h"
#import "FMAnimator.h"
#import <UIKit/UIGestureRecognizerSubclass.h>


@interface FMInertialState : NSObject

@property (nonatomic, readonly) CGFloat value;
@property (nonatomic, readonly) CGFloat velocity;
@property (nonatomic, readonly) CFAbsoluteTime timestamp;
@property (nonatomic, readonly) CGFloat dampingCoefficent;
@property (nonatomic) NSTimeInterval maxDuration;

- (instancetype)initWithMaxDuration:(CGFloat)duration
NS_DESIGNATED_INITIALIZER;

- (instancetype)init
UNAVAILABLE_ATTRIBUTE;

- (void)updateWithValue:(CGFloat)value time:(CFAbsoluteTime)time;
- (void)haltWithValue:(CGFloat)value time:(CFAbsoluteTime)time;
- (void)updateWithTime:(CFAbsoluteTime)time;

@end
@implementation FMInertialState

static const CGFloat VEC_THRESHOLD = 0.125;

- (instancetype)initWithMaxDuration:(CGFloat)duration
{
    self = [super init];
    if(self) {
        _maxDuration = duration;
    }
    return self;
}

- (void)haltWithValue:(CGFloat)value time:(CFAbsoluteTime)time
{
    _value = value;
    _velocity = 0;
    _timestamp = time;
    _dampingCoefficent = 0;
}

- (void)updateWithValue:(CGFloat)value time:(CFAbsoluteTime)time
{
    const NSTimeInterval timeDiff = time - _timestamp;
    const CGFloat valueDiff = value - _value;
    _value = value;
    _timestamp = time;
    if(timeDiff > 0) {
        _velocity = (0.3 * _velocity) + (0.7 * (valueDiff / timeDiff));
        const CGFloat k = log(fabs(_velocity / VEC_THRESHOLD)) / _maxDuration;
        _dampingCoefficent = MAX(4, k);
    }
}

- (void)updateWithTime:(CFAbsoluteTime)time
{
    const NSTimeInterval diff = time - _timestamp;
    _timestamp = time;
    const CGFloat oldm = _velocity;
    if(oldm != 0 && diff > 0) {
        const CGFloat newm = oldm * exp(-(_dampingCoefficent * diff));
        _value += (newm + oldm) * diff / 2;
        _velocity = (fabs(newm) > VEC_THRESHOLD) ? newm : 0;
    }
}

@end




@interface FMGestureInterpreter() <FMPanGestureRecognizerDelegate>

@property (readonly, nonatomic) CGPoint currentTranslation;
@property (readonly, nonatomic) CGFloat currentScale;

@property (assign, nonatomic) CGPoint translationCumulative;
@property (assign, nonatomic) CGSize  scaleCumulative;

@property (nonatomic, readonly) FMInertialState *transVX;
@property (nonatomic, readonly) FMInertialState *transVY;

@property (readonly, nonatomic) NSArray<id<FMInteraction>> *cumulatives;

- (void)handlePanning:(FMPanGestureRecognizer *)recognizer;
- (void)handlePinching:(UIPinchGestureRecognizer *)reconginer;

@end



@interface FMInertialPanAnimatioin : NSObject<FMAnimation>

@property (nonatomic, readonly) BOOL canceled;
@property (nonatomic, readonly) FMGestureInterpreter *interpreter;

@end
@implementation FMInertialPanAnimatioin

- (instancetype)initWithInterpreter:(FMGestureInterpreter *)interpreter
{
    self = [super init];
    if(self) {
        _interpreter = interpreter;
        _canceled = NO;
    }
    return self;
}

- (BOOL)shouldStartAnimating:(NSArray<id<FMAnimation>> *)currentAnimations timestamp:(NSTimeInterval)timestamp
{
    return YES;
}

- (BOOL)requestCancel
{
    _canceled = YES;
    return YES;
}

- (void)addedToPendingQueue:(NSTimeInterval)timestamp
{
}

- (BOOL)animate:(id<MTLCommandBuffer>)buffer timestamp:(NSTimeInterval)timestamp
{
    if(_canceled) return YES;
    
    FMInertialState *x = self.interpreter.transVX;
    FMInertialState *y = self.interpreter.transVY;
    [x updateWithTime:timestamp];
    [y updateWithTime:timestamp];
    self.interpreter.translationCumulative = CGPointMake(x.value, y.value);
    BOOL r = (x.velocity == 0 && y.velocity == 0);
    return r;
}

+ (instancetype)animation:(FMGestureInterpreter *)interpreter
{
    return [[self alloc] initWithInterpreter:interpreter];
}

@end






@implementation FMGestureInterpreter

@dynamic orientationStepDegree;

- (instancetype)initWithPanRecognizer:(FMPanGestureRecognizer *)pan
					  pinchRecognizer:(UIPinchGestureRecognizer *)pinch
						  restriction:(id<FMInterpreterStateRestriction> _Nullable)restriction
{
	self = [super init];
	if(self) {
		_cumulatives = [NSArray array];
		_orientationStep = M_PI_4; // 45 degree.
		_scaleCumulative = CGSizeMake(1, 1);
		_translationCumulative = CGPointZero;
        _transVX = [[FMInertialState alloc] initWithMaxDuration:2];
        _transVY = [[FMInertialState alloc] initWithMaxDuration:2];
		self.panRecognizer = pan;
		self.pinchRecognizer = pinch;
		_stateRestriction = restriction;
	}
	return self;
}

- (CGFloat)orientationStepDegree { return _orientationStep * 180 / M_PI; }
- (void)setOrientationStepDegree:(CGFloat)degree { _orientationStep = degree * M_PI / 180; }

- (void)setStateRestriction:(id<FMInterpreterStateRestriction>)stateRestriction
{
	if(_stateRestriction != stateRestriction) {
		BOOL changed = NO;
		_stateRestriction = stateRestriction;
		{
			const CGPoint oldT = _translationCumulative;
			self.translationCumulative = oldT;
			const CGPoint newT = _translationCumulative;
			changed |= (!CGPointEqualToPoint(oldT, newT));
		}
		{
			const CGSize oldS = _scaleCumulative;
			self.scaleCumulative = oldS;
			const CGSize newS = _scaleCumulative;
			changed |= (!CGSizeEqualToSize(oldS, newS));
		}
		if(changed) {
			NSArray<id<FMInteraction>> *cumulatives = _cumulatives;
			for(id<FMInteraction> object in cumulatives) {
				[object didTranslationChange:self];
			}
		}
	}
}

- (void)didBeginTouchesInRecognizer:(FMPanGestureRecognizer *)recognizer
{
    if(recognizer == self.panRecognizer) {
        const CFAbsoluteTime time = CFAbsoluteTimeGetCurrent();
        [_transVX haltWithValue:_translationCumulative.x time:time];
        [_transVY haltWithValue:_translationCumulative.y time:time];
    }
}

- (void)handlePanning:(FMPanGestureRecognizer *)recognizer
{
    FMAnimator *animator = self.momentumAnimator;
	const UIGestureRecognizerState state = recognizer.state;
	UIView *view = recognizer.view;
    const CFAbsoluteTime time = CFAbsoluteTimeGetCurrent();
    const BOOL began = (state == UIGestureRecognizerStateBegan);
    const BOOL progress = (state == UIGestureRecognizerStateChanged);
    const BOOL end = (state == UIGestureRecognizerStateEnded);
	if(began) {
		_currentTranslation = [recognizer translationInView:recognizer.view];
        [_transVX haltWithValue:_translationCumulative.x time:time];
        [_transVY haltWithValue:_translationCumulative.y time:time];
	} else if (progress || end) {
		const CGSize size = view.bounds.size;
		const CGPoint t = [recognizer translationInView:recognizer.view];
		// window座標とグラフの座標ではy軸の向きが違う。この時点でyの値を反転させておく.
		const CGPoint diff = {(t.x - _currentTranslation.x)/size.width, -(t.y - _currentTranslation.y)/size.height};
		_currentTranslation = t;
		
		const CGFloat dist = sqrt((diff.x*diff.x) + (diff.y*diff.y));
		if(dist > 0 && !isnan(dist)) {
			const CGFloat or_rad = atan2(diff.y, diff.x);
			const CGFloat stepped = (_orientationStep > 0) ? round(or_rad/_orientationStep) * _orientationStep : or_rad;
			const CGPoint oldT = _translationCumulative;
			const CGFloat dx = (dist * cos(stepped) / (_scaleCumulative.width));
			const CGFloat dy = (dist * sin(stepped) / (_scaleCumulative.height));
            const CGPoint newT = CGPointMake(oldT.x + dx, oldT.y + dy);
            [_transVX updateWithValue:newT.x time:time];
            [_transVY updateWithValue:newT.y time:time];
            self.translationCumulative = newT;
			
		}
        if(end && animator) {
            [animator addAnimation:[FMInertialPanAnimatioin animation:self]];
        }
    } else {
    }
}

- (void)handlePinching:(UIPinchGestureRecognizer *)reconginer
{
	const UIGestureRecognizerState state = reconginer.state;
	if(state == UIGestureRecognizerStateBegan) {
		_currentScale = reconginer.scale;
	} else if (state == UIGestureRecognizerStateChanged) {
		const CGFloat scale = reconginer.scale;
		const CGFloat scaleDiff = (scale / _currentScale) - 1; // -1よりは大きい.
		_currentScale = scale;
		if(reconginer.numberOfTouches == 2) {
			UIView *v = reconginer.view;
			const CGPoint a = [reconginer locationOfTouch:0 inView:v];
			const CGPoint b = [reconginer locationOfTouch:1 inView:v];
			// a,bと指の対応関係は実行時に変わるが、すでにscaleが取れている以上、右側の指が上だろうが下だろうが結果は変わらない.
			const CGPoint diff = {fabs(b.x-a.x), fabs(b.y-a.y)};
			const CGFloat dist = (diff.x*diff.x) + (diff.y*diff.y);
			if(dist > 0 && !isnan(dist)) {
				const CGFloat or_rad = atan2(diff.y, diff.x);
				const CGFloat stepped = (_orientationStep > 0) ? round(or_rad/_orientationStep) * _orientationStep : or_rad;
				const CGSize oldScale = _scaleCumulative;
				const CGFloat dw = (1 + (scaleDiff * cos(stepped)));
				const CGFloat dh = (1 + (scaleDiff * sin(stepped)));
				self.scaleCumulative = CGSizeMake(oldScale.width * dw, oldScale.height * dh);
//				const CGSize newScale = _scaleCumulative;
			}
		}
	}
}

- (void)setTranslationCumulative:(CGPoint)translationCumulative
{
    const CGPoint oldT = _translationCumulative;
	[_stateRestriction interpreter:self willTranslationChange:&translationCumulative];
	_translationCumulative = translationCumulative;
    if(!CGPointEqualToPoint(oldT, translationCumulative)) {
        NSArray<id<FMInteraction>> *cumulatives = _cumulatives;
        for(id<FMInteraction> object in cumulatives) {
            [object didTranslationChange:self];
        }
    }
}

- (void)setScaleCumulative:(CGSize)scaleCumulative
{
    const CGSize oldScale = _scaleCumulative;
	[_stateRestriction interpreter:self willScaleChange:&scaleCumulative];
	_scaleCumulative = scaleCumulative;
    if(!CGSizeEqualToSize(oldScale, scaleCumulative)) {
        NSArray<id<FMInteraction>> *cumulatives = _cumulatives;
        for(id<FMInteraction> object in cumulatives) {
            [object didScaleChange:self];
        }
    }
}

- (void)dealloc
{
	self.panRecognizer = nil;
	self.pinchRecognizer = nil;
}

- (void)addInteraction:(id<FMInteraction>)object
{
	@synchronized(self) {
		_cumulatives = [_cumulatives arrayByAddingObjectIfNotExists:object];
	}
}

- (void)removeInteraction:(id<FMInteraction>)object
{
	@synchronized(self) {
		_cumulatives = [_cumulatives arrayByRemovingObject:object];
	}
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

- (void)resetStates
{
	_translationCumulative = CGPointZero;
	_scaleCumulative = CGSizeMake(1, 1);
}

@end





@implementation FMDefaultInterpreterRestriction

- (instancetype)initWithScaleMin:(CGSize)minScale
							 max:(CGSize)maxScale
				  translationMin:(CGPoint)minTrans
							 max:(CGPoint)maxTrans
{
	self = [super init];
	if(self) {
		_minScale = minScale;
		_maxScale = maxScale;
		_minTranslation = minTrans;
		_maxTranslation = maxTrans;
	}
	return self;
}

- (void)interpreter:(FMGestureInterpreter *)interpreter willScaleChange:(CGSize *)size
{
	size->width = MIN(_maxScale.width, MAX(_minScale.width, size->width));
	size->height = MIN(_maxScale.height, MAX(_minScale.height, size->height));
}

- (void)interpreter:(FMGestureInterpreter *)interpreter willTranslationChange:(CGPoint *)translation
{
	translation->x = MIN(_maxTranslation.x, MAX(_minTranslation.x, translation->x));
	translation->y = MIN(_maxTranslation.y, MAX(_minTranslation.y, translation->y));
}

@end





@implementation FMDefaultDimensionalRestriction

- (instancetype)initWithScaleMin:(CGFloat)minScale
                             max:(CGFloat)maxScale
                        transMin:(CGFloat)minTrans
                             max:(CGFloat)maxTrans
{
    self = [super init];
    if(self) {
        _minScale = minScale;
        _maxScale = maxScale;
        _minTranslation = minTrans;
        _maxTranslation = maxTrans;
    }
    return self;
}

+ (instancetype)fixedRangeRestriction
{
    return [[self alloc] initWithScaleMin:1 max:1 transMin:0 max:0];
}

- (void)interpreter:(FMGestureInterpreter *)interpreter willTranslationChange:(CGFloat *)translation
{
    *translation = MIN(_maxTranslation, MAX(_minTranslation, *translation));
}

- (void)interpreter:(FMGestureInterpreter *)interpreter willScaleChange:(CGFloat *)scale
{
    *scale = MIN(_maxScale, MAX(_minScale, *scale));
}

@end

@interface FMRangedDimensionalRestriction()

@end
@implementation FMRangedDimensionalRestriction

- (instancetype)initWithAccessibleRange:(FMDefaultRestriction *)accessible
                            windowRange:(FMDefaultRestriction *)window
                              minLength:(CGFloat)minLength
                              maxLength:(CGFloat)maxLength
{
    self = [super init];
    if(self) {
        _accessibleRange = accessible;
        _windowRange = window;
        _minLength = minLength;
        _maxLength = maxLength;
    }
    return self;
}

- (void)interpreter:(FMGestureInterpreter *)interpreter willScaleChange:(CGFloat *)scale
{
    const CGFloat windowLen = self.windowRange.currentLength;
    if(windowLen > 0) {
        const CGFloat minScale = _maxLength / windowLen;
        const CGFloat maxScale = _minLength / windowLen;
        *scale = MIN(maxScale, MAX(minScale, *scale));
    } else {
        *scale = 1;
    }
}

- (void)interpreter:(FMGestureInterpreter *)interpreter willTranslationChange:(CGFloat *)translation
{
    const CGFloat windowLen = self.windowRange.currentLength;
    const CGFloat accessLen = self.accessibleRange.currentLength;
    if(windowLen > 0 && accessLen > 0) {
        const CGFloat max = - (self.accessibleRange.currentMin - self.windowRange.currentMin) / windowLen;
        const CGFloat min = - (self.accessibleRange.currentMax - self.windowRange.currentMax) / windowLen;
        *translation = MIN(max, MAX(min, *translation));
    } else {
        *translation = 0;
    }
}

@end





@implementation FMInterpreterDetailedRestriction

- (instancetype)initWithXRestriction:(id<FMInterpreterDimensionalRestroction>)x
						yRestriction:(id<FMInterpreterDimensionalRestroction>)y
{
	self = [super init];
	if(self) {
		_x = x;
		_y = y;
	}
	return self;
}

- (void)interpreter:(FMGestureInterpreter *)interpreter willScaleChange:(CGSize *)size
{
	[_x interpreter:interpreter willScaleChange:&(size->width)];
	[_y interpreter:interpreter willScaleChange:&(size->height)];
}

- (void)interpreter:(FMGestureInterpreter *)interpreter willTranslationChange:(CGPoint *)translation
{
	[_x interpreter:interpreter willTranslationChange:&(translation->x)];
	[_y interpreter:interpreter willTranslationChange:&(translation->y)];
}

@end





@interface FMSimpleBlockInteraction()

@property (copy, nonatomic) SimpleInteractionBlock _Nonnull block;

@end
@implementation FMSimpleBlockInteraction

- (instancetype)initWithBlock:(SimpleInteractionBlock)block
{
	self = [super init];
	if(self) {
		self.block = block;
	}
	return self;
}

- (void)didScaleChange:(FMGestureInterpreter *)interpreter { _block(interpreter); }

- (void)didTranslationChange:(FMGestureInterpreter *)interpreter { _block(interpreter); }

+ (instancetype)connectUpdaters:(NSArray<FMProjectionUpdater *> *)updaters
                  toInterpreter:(FMGestureInterpreter *)interpreter
                   orientations:(NSArray<NSNumber *> * _Nonnull)orientations
{
    if(updaters.count == orientations.count) {
        const NSInteger count = updaters.count;
        for(NSInteger i = 0; i < count; ++i) {
            const CGFloat orientation = (CGFloat)(orientations[i].doubleValue);
            id<FMRestriction> r = [[FMUserInteractiveRestriction alloc] initWithGestureInterpreter:interpreter orientation:orientation];
            [(updaters[i]) addRestrictionToLast:r];
        }
    }
    FMSimpleBlockInteraction *obj = [[self alloc] initWithBlock:^(FMGestureInterpreter * _Nonnull interpreter) {
        for(FMProjectionUpdater *updater in updaters) {
            [updater updateTarget];
        }
    }];
    [interpreter addInteraction:obj];
    return obj;
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


