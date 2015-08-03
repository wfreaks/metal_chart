//
//  LineEngine.m
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/08/03.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "LineEngine.h"
#import <Metal/Metal.h>
#import "LineEngine_common.h"

@interface LineEngine()

@property (strong, nonatomic) DeviceResource *resource;
@property (assign, nonatomic) NSUInteger capacity;

@property (strong, nonatomic) id<MTLBuffer> vertexBuffer;
@property (strong, nonatomic) id<MTLBuffer> indexBuffer;
@property (strong, nonatomic) id<MTLBuffer> projectionBuffer;
@property (strong, nonatomic) id<MTLBuffer> attributesBuffer;

@end

@implementation LineEngine

- (id)initWithResource:(DeviceResource *)resource
		bufferCapacity:(NSUInteger)capacity
{
	self = [super init];
	if(self) {
		self.resource = [DeviceResource defaultResource];
		self.capacity = capacity;
	}
	return self;
}

@end
