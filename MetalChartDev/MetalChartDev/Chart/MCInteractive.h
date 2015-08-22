//
//  MCInteractive.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/22.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MCGestureInterpreter;

@protocol MCDifferenceInteraction <NSObject>

// arg orientation represents radian between vector (1,0) and translation/scale vector.
- (void)interpreter:(MCGestureInterpreter * _Nonnull)interpreter
	didScaleChanged:(CGSize)scaleDiff
;
		
- (void)interpreter:(MCGestureInterpreter * _Nonnull)interpreter
didTranslationChanged:(CGPoint)translationDiff
;

@end

@protocol MCCumulativeInteraction <NSObject>

- (void)didScaleChange:(MCGestureInterpreter * _Nonnull)interpreter;
	
- (void)didTranslationChange:(MCGestureInterpreter * _Nonnull)interpreter;

@end

@protocol MCInterpreterStateRestriction<NSObject>

- (void)interpreter:(MCGestureInterpreter * _Nonnull)interpreter
	willScaleChange:(CGSize * _Nonnull)size;

- (void)interpreter:(MCGestureInterpreter * _Nonnull)interpreter
willTranslationChange:(CGPoint * _Nonnull)translation;

@end

@interface MCGestureInterpreter : NSObject

@property (strong, nonatomic) UIPanGestureRecognizer * _Nullable panRecognizer;
@property (strong, nonatomic) UIPinchGestureRecognizer * _Nullable pinchRecognizer;
@property (strong, nonatomic) id<MCInterpreterStateRestriction> _Nullable restriction;

@property (assign, nonatomic) CGFloat orientationStep;
@property (assign, nonatomic) CGFloat orientationStepDegree;

@property (readonly, nonatomic) CGPoint currentTranslation;
@property (readonly, nonatomic) CGFloat currentScale;

- (instancetype _Null_unspecified)initWithPanRecognizer:(UIPanGestureRecognizer * _Nullable)pan
										pinchRecognizer:(UIPinchGestureRecognizer * _Nullable)pinch
										restriction:(id<MCInterpreterStateRestriction> _Nullable)restriction
;

- (void)resetCumulativeStates;

- (void)addDifference:(id<MCDifferenceInteraction> _Nonnull)object;
- (void)removeDifference:(id<MCDifferenceInteraction> _Nonnull)object;

- (void)addCumulative:(id<MCDifferenceInteraction> _Nonnull)object;
- (void)removeCumulative:(id<MCDifferenceInteraction> _Nonnull)object;

@end

