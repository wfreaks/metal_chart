//
//  FMAnimator.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/09/01.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MetalChart.h"

@protocol FMAnimation

// 他のアニメーションからキャンセルを要求したりする時用. 特にAnimatorでは利用しない. 戻り値は想定としては、受理されたか否か.
- (BOOL)requestCancel;

// まず追加された時このメソッドが呼ばれる. タイミング調整などに.
- (void)addedToPendingQueue:(NSTimeInterval)timestamp;

// 次、描画開始前にループでpendingQueueの中身は一律このメソッドが呼ばれる.
// ここでYESを返すとrunningQueueに移動し、animate:timestamp が呼ばれるようになる.
- (BOOL)shouldStartAnimating:(NSArray<id<FMAnimation>> * _Nonnull)currentAnimations timestamp:(NSTimeInterval)timestamp;

// YESを返すと終了したとみなされる.
- (BOOL)animate:(id<MTLCommandBuffer> _Nonnull)buffer timestamp:(NSTimeInterval)timestamp;
 
@end



@interface FMAnimator : NSObject <FMCommandBufferHook>

@property (nonatomic, weak) MetalView * _Nullable metalView;

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
