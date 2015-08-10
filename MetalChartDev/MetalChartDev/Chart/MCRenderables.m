//
//  MCRenderables.m
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/11.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "MCRenderables.h"
#import "Lines.h"

@implementation MCLineSeries

- (instancetype)initWithLine:(Line *)line
{
	self = [super init];
	if(self) {
		_line = line;
	}
	return self;
}

- (void)renderWithCommandBuffer:(id<MTLCommandBuffer>)buffer
					 renderPass:(MTLRenderPassDescriptor *)pass
					 projection:(UniformProjection *)projection
{
	[_line encodeTo:buffer renderPass:pass projection:projection];
}

@end
