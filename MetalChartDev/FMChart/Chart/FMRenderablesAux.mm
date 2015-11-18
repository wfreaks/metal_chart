//
//  FMRenderablesAux.m
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/11/18.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "FMRenderablesAux.h"

#import "Engine.h"
#import "Buffers.h"
#import "FMProjections.h"
#import "CircleBuffers.h"
#import "Circles.h"



@interface FMPieDoughtSeries()

@end
@implementation FMPieDoughtSeries

- (instancetype)initWithEngine:(FMEngine *)engine
						   arc:(FMContinuosArcPrimitive *)arc
					projection:(FMProjectionPolar *)projection
						values:(FMIndexedFloatBuffer *)values
			  capacityOnCreate:(NSUInteger)capacity
{
	self = [super init];
	if(self) {
		_arc = arc;
		_projection = projection;
		_values = (values) ? values : [[FMIndexedFloatBuffer alloc] initWithResource:engine.resource capacity:capacity];
	}
	return self;
}

- (FMUniformArcConfiguration *)conf { return _arc.configuration; }
- (FMUniformArcAttributesArray *)attrs { return _arc.attributes; }
- (NSUInteger)capacity { return _values.capacity; }

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
			 chart:(MetalChart *)chart
{
	FMProjectionPolar *projection = _projection;
	const NSUInteger count = _count;
	const NSUInteger offset = _offset;
	if(projection && count > 0) {
		[_arc encodeWith:encoder projection:projection.projection values:_values offset:offset count:count];
	}
}

@end

