//
//  FMAnimator.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/09/01.
//  Copyright © 2015 Keisuke Mori. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMMetalChart.h"

/**
 * FMAnimation protocol defines methods in order for an object to behave as a animation.
 * Animation objects added to pending queue will be notified when
 * 1. added to pending queue (to allow them to resolve conflicts with aminations currently running)
 * 2. drawing loop starts animation handling if pending (to determin whether they should start animating or keep awaiting)
 * 3. should perform animation
 * 
 * The method 'requestCancel' is defined to be used for resolving confliction (case 1).
 * Default implementations of this protocol return YES when they accept requests, but it is just a convetion.
 */

@protocol FMAnimation <NSObject>

- (BOOL)requestCancel;

- (void)addedToPendingQueueOfAnimator:(FMAnimator* _Nonnull)animator timestamp:(CFAbsoluteTime)timestamp;

/**
 * If animation object return YES, it will be removed from a pending queue, added to a running queue, then its animate:animate:timestamp: will get called
 * in drawing loop.
 */
- (BOOL)animator:(FMAnimator* _Nonnull)animator shouldStartAnimating:(CFAbsoluteTime)timestamp;

/**
 * An animation object should perform animation (MTLCommandBuffer is available, if required to do so).
 * If an object returns YES, it will be removed from running queue.
 */

- (BOOL)animator:(FMAnimator* _Nonnull)animator animate:(id<MTLCommandBuffer> _Nonnull)buffer timestamp:(CFAbsoluteTime)timestamp;
 
@end


/**
 * FMAnimator object handles animation objects which implements FMAnimation protocol as a hook to FMChart object.
 *
 * 'metalView' property is used to notify updates (setNeedsDisplay).
 * Any animation object remained in its pending queue and running queue triggers [metalView setNeedsDisplay] at the end of drawing loop.
 * (Naturally addAnimation: has the same effects)
 */

@interface FMAnimator : NSObject <FMCommandBufferHook>

@property (nonatomic, readonly) NSOrderedSet<id<FMAnimation>> * _Nonnull runningAnimations;
@property (nonatomic, readonly) NSOrderedSet<id<FMAnimation>> * _Nonnull pendingAnimations;

@property (nonatomic, weak) FMMetalView * _Nullable metalView;

- (void)addAnimation:(id<FMAnimation> _Nonnull)animation;

@end


/**
 * Default implementation of FMAnimation protocol using blocks.
 * An instance of this class does not handle cancel requests.
 * Duration and delay are implemented using timestamp.
 * Block arguments 'progress' is in range [0,1].
 */

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
