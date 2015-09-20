//
//  MCAnimator.h
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/09/01.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MetalChart.h"

@protocol MCAnimation

- (BOOL)requestCancel;
- (void)addedToPendingQueue:(NSTimeInterval)timestamp;
- (BOOL)shouldStartAnimating:(NSArray<id<MCAnimation>> * _Nonnull)currentAnimations timestamp:(NSTimeInterval)timestamp;
- (BOOL)animate:(id<MTLCommandBuffer> _Nonnull)buffer timestamp:(NSTimeInterval)timestamp;
 
@end



@interface MCAnimator : NSObject <MCCommandBufferHook>

- (void)addAnimation:(id<MCAnimation> _Nonnull)animation;

@end

typedef void (^MCAnimationBlock)(float progress);

@interface MCBlockAnimation : NSObject <MCAnimation>

@property (readonly, nonatomic) NSTimeInterval duration;
@property (readonly, nonatomic) NSTimeInterval delay;

- (instancetype _Nonnull)initWithDuration:(NSTimeInterval)duration
                                             delay:(NSTimeInterval)delay
                                             Block:(MCAnimationBlock _Nonnull)block
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;


@end
