//
//  MCInteractive.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/22.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MCDifferenceInteraction <NSObject>

// arg orientation represents radian between vector (1,0) and translation/scale vector.
- (void)scaleChanged:(CGFloat)scaleDiff orientation:(CGFloat)orientation;
- (void)translationChanged:(CGFloat)translationDiff orientation:(CGFloat)orientation;

@end

@protocol MCCumulativeInteraction <NSObject>

- (void)scaleChanged:(CGSize)scale;
- (void)translationChanged:(CGPoint)translation;

@end


@interface MCGestureInterpreter : NSObject

@property (strong, nonatomic) UIPanGestureRecognizer * _Nullable panRecognizer;
@property (strong, nonatomic) UIPinchGestureRecognizer * _Nullable pinchRecognizer;

@property (assign, nonatomic) CGFloat orientationStep;
@property (assign, nonatomic) CGFloat orientationStepDegree;

- (instancetype _Null_unspecified)initWithPanRecognizer:(UIPanGestureRecognizer * _Nullable)pan
										pinchRecognizer:(UIPinchGestureRecognizer * _Nullable)pinch
;

- (void)resetCumulativeStates;

@end

