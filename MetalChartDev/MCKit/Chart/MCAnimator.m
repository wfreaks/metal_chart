//
//  MCAnimator.m
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/09/01.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "MCAnimator.h"
#import "NSArray+Utility.h"

@interface MCAnimator()

@property (strong, nonatomic) NSArray<id<MCAnimation>> * _Nonnull runningAnimations;
@property (strong, nonatomic) NSArray<id<MCAnimation>> * _Nonnull pendingAnimations;

@end

@interface MCBlockAnimation()

@property (copy  , nonatomic) MCAnimationBlock block;
@property (assign, nonatomic) NSTimeInterval anchorTime;

@end

@implementation MCAnimator

- (instancetype)init
{
    self = [super init];
    if(self) {
        _runningAnimations = [NSArray array];
        _pendingAnimations = [NSArray array];
    }
    return self;
}

- (void)chart:(MetalChart *)chart willStartEncodingToBuffer:(id<MTLCommandBuffer>)buffer
{
    NSArray<id<MCAnimation>> * running;
    NSArray<id<MCAnimation>> * pending;
    const NSTimeInterval timestamp = CFAbsoluteTimeGetCurrent();
    
    @synchronized(self) {
        running = _runningAnimations;
        pending = _pendingAnimations;
    }
    
    for(id<MCAnimation> a in pending) {
        if([a shouldStartAnimating:running timestamp:timestamp]) {
            running = [running arrayByAddingObject:a];
            [self removePendingAnimation:a];
        }
    }
    
    NSArray<id<MCAnimation>> * newRunning = running;
    for(id<MCAnimation> a in running) {
        if([a animate:buffer timestamp:timestamp]) {
            newRunning = [newRunning arrayByRemovingObject:a];
        }
    }
    
    _runningAnimations = newRunning;
}

- (void)chart:(MetalChart *)chart willCommitBuffer:(id<MTLCommandBuffer>)buffer
{
    
}

- (void)addAnimation:(id<MCAnimation>)animation
{
    @synchronized(self) {
        [animation addedToPendingQueue:CFAbsoluteTimeGetCurrent()];
        _pendingAnimations = [_pendingAnimations arrayByAddingObjectIfNotExists:animation];
    }
}

- (void)removePendingAnimation:(id<MCAnimation>)animation
{
    @synchronized(self) {
        _pendingAnimations = [_pendingAnimations arrayByRemovingObject:animation];
    }
}

@end

@implementation MCBlockAnimation

- (instancetype)initWithDuration:(NSTimeInterval)duration
                           delay:(NSTimeInterval)delay
                           Block:(MCAnimationBlock)block
{
    self = [super init];
    if(self) {
        self.block = block;
        _duration = MAX(0.1, duration); // progressの計算で分母になるので最低持続時間を設ける.
        _delay = MAX(0, delay);
    }
    return self;
}

- (BOOL)requestCancel { return NO; }
- (void)addedToPendingQueue:(NSTimeInterval)timestamp { _anchorTime = timestamp; }

- (BOOL)shouldStartAnimating:(NSArray<id<MCAnimation>> *)currentAnimations timestamp:(NSTimeInterval)timestamp
{
    return (_anchorTime + _delay <= timestamp);
}

- (BOOL)animate:(id<MTLCommandBuffer>)buffer timestamp:(NSTimeInterval)timestamp
{
    const float progress = (float)((timestamp - (_anchorTime + _delay)) / _duration);
    _block(progress);
    return (progress >= 1.0);
}

@end






