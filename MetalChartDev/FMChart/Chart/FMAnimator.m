//
//  FMAnimator.m
//  FMChart
//
//  Created by Keisuke Mori on 2015/09/01.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "FMAnimator.h"
#import "NSArray+Utility.h"

@interface FMAnimator()

@property (strong, nonatomic) NSArray<id<FMAnimation>> * _Nonnull runningAnimations;
@property (strong, nonatomic) NSArray<id<FMAnimation>> * _Nonnull pendingAnimations;

@end

@interface FMBlockAnimation()

@property (copy  , nonatomic) FMAnimationBlock block;
@property (assign, nonatomic) NSTimeInterval anchorTime;

@end

@implementation FMAnimator

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
	NSArray<id<FMAnimation>> * running;
	NSArray<id<FMAnimation>> * pending;
	const NSTimeInterval timestamp = CFAbsoluteTimeGetCurrent();
	
	@synchronized(self) {
		running = _runningAnimations;
		pending = _pendingAnimations;
	}
	
	for(id<FMAnimation> a in pending) {
		if([a shouldStartAnimating:running timestamp:timestamp]) {
			running = [running arrayByAddingObject:a];
			[self removePendingAnimation:a];
		}
	}
	
	NSArray<id<FMAnimation>> * newRunning = running;
	for(id<FMAnimation> a in running) {
		if([a animate:buffer timestamp:timestamp]) {
			newRunning = [newRunning arrayByRemovingObject:a];
		}
	}
	
	_runningAnimations = newRunning;
}

- (void)chart:(MetalChart *)chart willCommitBuffer:(id<MTLCommandBuffer>)buffer
{
	@synchronized (self) {
		if(_runningAnimations.count + _pendingAnimations.count > 0) {
			[_metalView setNeedsDisplay];
		}
	}
}

- (void)addAnimation:(id<FMAnimation>)animation
{
	@synchronized(self) {
		[animation addedToPendingQueue:CFAbsoluteTimeGetCurrent()];
		_pendingAnimations = [_pendingAnimations arrayByAddingObjectIfNotExists:animation];
		MetalView *view = self.metalView;
		if(view) {
			[view setNeedsDisplay];
		}
	}
}

- (void)removePendingAnimation:(id<FMAnimation>)animation
{
	@synchronized(self) {
		_pendingAnimations = [_pendingAnimations arrayByRemovingObject:animation];
	}
}

@end

@implementation FMBlockAnimation

- (instancetype)initWithDuration:(NSTimeInterval)duration
						   delay:(NSTimeInterval)delay
						   Block:(FMAnimationBlock)block
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

- (BOOL)shouldStartAnimating:(NSArray<id<FMAnimation>> *)currentAnimations timestamp:(NSTimeInterval)timestamp
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






