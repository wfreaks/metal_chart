//
//  FMAnimator.h
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/09/01.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MetalChart.h"

@protocol FMAnimation

- (BOOL)requestCancel;
- (void)addedToPendingQueue:(NSTimeInterval)timestamp;
- (BOOL)shouldStartAnimating:(NSArray<id<FMAnimation>> * _Nonnull)currentAnimations timestamp:(NSTimeInterval)timestamp;
- (BOOL)animate:(id<MTLCommandBuffer> _Nonnull)buffer timestamp:(NSTimeInterval)timestamp;
 
@end



@interface FMAnimator : NSObject <FMCommandBufferHook>

- (void)addAnimation:(id<FMAnimation> _Nonnull)animation;

@end

typedef void (^FMAnimationBlock)(float progress);

@interface FMBlockAnimation : NSObject <FMAnimation>

@property (readonly, nonatomic) NSTimeInterval duration;
@property (readonly, nonatomic) NSTimeInterval delay;

- (instancetype _Nonnull)initWithDuration:(NSTimeInterval)duration
									delay:(NSTimeInterval)delay
									Block:(FMAnimationBlock _Nonnull)block
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;


@end
