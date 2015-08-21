//
//  MCInteractive.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/22.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MCInteractive <NSObject>

- (void)scaleChanged:(CGFloat)scaleDiff orientation:(CGFloat)orientation;
- (void)translationChanged:(CGFloat)translationDiff orientation:(CGFloat)orientation;

@end



@interface MCGestureInterpreter : NSObject

@property (strong, nonatomic) UIPanGestureRecognizer * _Nullable panRecognizer;
@property (strong, nonatomic) UIPinchGestureRecognizer * _Nullable pinchRecognizer;

@property (readonly, nonatomic) NSArray<id<MCInteractive>> * _Nonnull interactives;

@property (assign, nonatomic) CGFloat orientationStep;

- (instancetype _Null_unspecified)initWithPanRecognizer:(UIPanGestureRecognizer * _Nullable)pan
										pinchRecognizer:(UIPinchGestureRecognizer * _Nullable)pinch
;

- (void)addInteractive:(id<MCInteractive> _Nonnull)object;

- (void)removeInteractive:(id<MCInteractive> _Nonnull)object;

@end

