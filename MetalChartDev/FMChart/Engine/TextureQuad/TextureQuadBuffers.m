//
//  TextureQuadBuffers.m
//  FMChart
//
//  Created by Keisuke Mori on 2015/09/16.
//  Copyright © 2015 Keisuke Mori. All rights reserved.
//

#import "TextureQuadBuffers.h"
#import <Metal/Metal.h>
#import "DeviceResource.h"

@implementation FMUniformRegion

@dynamic region;

- (instancetype)initWithResource:(FMDeviceResource *)resource
{
	self = [super init];
	if(self) {
		_buffer = [resource.device newBufferWithLength:sizeof(uniform_region) options:MTLResourceOptionCPUCacheModeWriteCombined];
	}
	return self;
}

- (uniform_region *)region { return (uniform_region *)[_buffer contents]; }

- (void)setBasePosition:(CGPoint)point
{
	self.region->base_pos = vector2((float)point.x, (float)point.y);
}

- (void)setAnchorPoint:(CGPoint)anchor
{
	self.region->anchor = vector2((float)anchor.x, (float)anchor.y);
}

- (void)setIterationVector:(CGPoint)vec
{
	self.region->iter_vec = vector2((float)vec.x, (float)vec.y);
}

- (void)setSize:(CGSize)size
{
	self.region->size = vector2((float)size.width, (float)size.height);
}

- (void)setIterationOffset:(CGFloat)offset
{
	self.region->iter_offset = (float)offset;
}

- (void)setPositionOffset:(CGPoint)offset
{
	self.region->offset = vector2((float)offset.x, (float)offset.y);
}

@end
