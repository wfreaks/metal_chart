//
//  MCInteractive.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/22.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MCGestureInterpreter;

@protocol MCInteraction <NSObject>

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

// readoly state properties (only user interaction & restriction cam modify these values).
@property (readonly, nonatomic) CGPoint translationCumulative;
@property (readonly, nonatomic) CGSize  scaleCumulative;

- (instancetype _Null_unspecified)initWithPanRecognizer:(UIPanGestureRecognizer * _Nullable)pan
										pinchRecognizer:(UIPinchGestureRecognizer * _Nullable)pinch
										restriction:(id<MCInterpreterStateRestriction> _Nullable)restriction
;

- (void)resetStates;

- (void)addInteraction:(id<MCInteraction> _Nonnull)object;
- (void)removeInteraction:(id<MCInteraction> _Nonnull)object;

@end


@interface MCDefaultInterpreterRestriction : NSObject<MCInterpreterStateRestriction>

@property (readonly, nonatomic) CGSize minScale;
@property (readonly, nonatomic) CGSize maxScale;
@property (readonly, nonatomic) CGPoint minTranslation;
@property (readonly, nonatomic) CGPoint maxTranslation;

- (instancetype _Null_unspecified)initWithScaleMin:(CGSize)minScale
											   max:(CGSize)maxScale
									translationMin:(CGPoint)minTrans
											   max:(CGPoint)maxTrans
;

@end

typedef void (^SimpleInterfactionBlock)(MCGestureInterpreter * _Nonnull);

@interface MCSimpleBlockInteraction : NSObject<MCInteraction>

- (instancetype _Null_unspecified)initWithBlock:(SimpleInterfactionBlock _Nonnull)block;

@end
