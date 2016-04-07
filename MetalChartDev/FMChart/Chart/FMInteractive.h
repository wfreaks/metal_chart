//
//  FMInteractive.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/22.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FMGestureInterpreter;
@class FMProjectionUpdater;
@class FMDefaultRestriction;
@class FMAnimator;
@class FMPanGestureRecognizer;


@protocol FMInteraction <NSObject>

- (void)didScaleChange:(FMGestureInterpreter * _Nonnull)interpreter;
- (void)didTranslationChange:(FMGestureInterpreter * _Nonnull)interpreter;

@end





@protocol FMInterpreterStateRestriction<NSObject>

- (void)interpreter:(FMGestureInterpreter * _Nonnull)interpreter
	willScaleChange:(CGSize * _Nonnull)size;

- (void)interpreter:(FMGestureInterpreter * _Nonnull)interpreter
willTranslationChange:(CGPoint * _Nonnull)translation;

@end





@interface FMGestureInterpreter : NSObject

@property (strong, nonatomic) FMPanGestureRecognizer * _Nullable panRecognizer;
@property (strong, nonatomic) UIPinchGestureRecognizer * _Nullable pinchRecognizer;
@property (strong, nonatomic) id<FMInterpreterStateRestriction> _Nullable stateRestriction;

@property (assign, nonatomic) CGFloat orientationStep;
@property (assign, nonatomic) CGFloat orientationStepDegree;

// readoly state properties (only user interaction & restriction cam modify these values).
@property (readonly, nonatomic) CGPoint translationCumulative;
@property (readonly, nonatomic) CGSize  scaleCumulative;

@property (nonatomic, weak) FMAnimator * _Nullable momentumAnimator;

- (instancetype _Nonnull)initWithPanRecognizer:(FMPanGestureRecognizer * _Nullable)pan
							   pinchRecognizer:(UIPinchGestureRecognizer * _Nullable)pinch
								   restriction:(id<FMInterpreterStateRestriction> _Nullable)restriction
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

- (void)resetStates;

- (void)addInteraction:(id<FMInteraction> _Nonnull)object;
- (void)removeInteraction:(id<FMInteraction> _Nonnull)object;

@end






@interface FMDefaultInterpreterRestriction : NSObject<FMInterpreterStateRestriction>

@property (readonly, nonatomic) CGSize minScale;
@property (readonly, nonatomic) CGSize maxScale;
@property (readonly, nonatomic) CGPoint minTranslation;
@property (readonly, nonatomic) CGPoint maxTranslation;

- (instancetype _Nonnull)initWithScaleMin:(CGSize)minScale
									  max:(CGSize)maxScale
						   translationMin:(CGPoint)minTrans
									  max:(CGPoint)maxTrans
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;


@end




// ２軸がくっついていると、正直細かいコントロールが効かないので分割して扱う事ができるようにする
@protocol FMInterpreterDimensionalRestroction<NSObject>

- (void)interpreter:(FMGestureInterpreter * _Nonnull)interpreter
	willScaleChange:(CGFloat * _Nonnull)scale;

- (void)interpreter:(FMGestureInterpreter * _Nonnull)interpreter
willTranslationChange:(CGFloat * _Nonnull)translation;

@end


@interface FMDefaultDimensionalRestriction : NSObject<FMInterpreterDimensionalRestroction>

@property (readonly, nonatomic) CGFloat minScale;
@property (readonly, nonatomic) CGFloat maxScale;
@property (readonly, nonatomic) CGFloat minTranslation;
@property (readonly, nonatomic) CGFloat maxTranslation;

- (instancetype _Nonnull)initWithScaleMin:(CGFloat)minScale
                                      max:(CGFloat)maxScale
                                 transMin:(CGFloat)minTrans
                                      max:(CGFloat)maxTrans
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

+ (instancetype _Nonnull)fixedRangeRestriction; // scaleもtranslateもしない.

@end


@interface FMRangedDimensionalRestriction : NSObject<FMInterpreterDimensionalRestroction>

@property (readonly, nonatomic) FMDefaultRestriction * _Nonnull accessibleRange;
@property (readonly, nonatomic) FMDefaultRestriction * _Nonnull windowRange;
@property (readonly, nonatomic) CGFloat minLength;
@property (readonly, nonatomic) CGFloat maxLength;

- (instancetype _Nonnull)initWithAccessibleRange:(FMDefaultRestriction * _Nonnull)accessible
                                     windowRange:(FMDefaultRestriction * _Nonnull)window
                                       minLength:(CGFloat)minLength
                                       maxLength:(CGFloat)maxLength
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init
UNAVAILABLE_ATTRIBUTE;

@end


@interface FMInterpreterDetailedRestriction : NSObject<FMInterpreterStateRestriction>

@property (readonly, nonatomic) id<FMInterpreterDimensionalRestroction> _Nonnull x;
@property (readonly, nonatomic) id<FMInterpreterDimensionalRestroction> _Nonnull y;

- (instancetype _Nonnull)initWithXRestriction:(id<FMInterpreterDimensionalRestroction> _Nonnull)x
								 yRestriction:(id<FMInterpreterDimensionalRestroction> _Nonnull)y
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

@end





typedef void (^SimpleInteractionBlock)(FMGestureInterpreter * _Nonnull);

@interface FMSimpleBlockInteraction : NSObject<FMInteraction>

- (instancetype _Nonnull)initWithBlock:(SimpleInteractionBlock _Nonnull)block
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;


+ (instancetype _Nonnull)connectUpdaters:(NSArray<FMProjectionUpdater*> * _Nonnull)updaters
						   toInterpreter:(FMGestureInterpreter * _Nonnull)interpreter
							orientations:(NSArray<NSNumber*> * _Nonnull)orientations;
;

@end


@protocol FMPanGestureRecognizerDelegate<NSObject>

- (void)didBeginTouchesInRecognizer:(FMPanGestureRecognizer * _Nonnull)recognizer;

@end


@interface FMPanGestureRecognizer : UIPanGestureRecognizer

@property (nonatomic, weak) IBOutlet id<FMPanGestureRecognizerDelegate> _Nullable recognizerDelegate;

@end

