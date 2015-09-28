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

@property (strong, nonatomic) UIPanGestureRecognizer * _Nullable panRecognizer;
@property (strong, nonatomic) UIPinchGestureRecognizer * _Nullable pinchRecognizer;
@property (strong, nonatomic) id<FMInterpreterStateRestriction> _Nullable stateRestriction;

@property (assign, nonatomic) CGFloat orientationStep;
@property (assign, nonatomic) CGFloat orientationStepDegree;

// readoly state properties (only user interaction & restriction cam modify these values).
@property (readonly, nonatomic) CGPoint translationCumulative;
@property (readonly, nonatomic) CGSize  scaleCumulative;

- (instancetype _Nonnull)initWithPanRecognizer:(UIPanGestureRecognizer * _Nullable)pan
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

typedef void (^SimpleInterfactionBlock)(FMGestureInterpreter * _Nonnull);

@interface FMSimpleBlockInteraction : NSObject<FMInteraction>

- (instancetype _Nonnull)initWithBlock:(SimpleInterfactionBlock _Nonnull)block
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;


+ (instancetype _Nonnull)connectUpdaters:(NSArray<FMProjectionUpdater*> * _Nonnull)updaters
						   toInterpreter:(FMGestureInterpreter * _Nonnull)interpreter
							orientations:(NSArray<NSNumber*> * _Nonnull)orientations;
;

@end
