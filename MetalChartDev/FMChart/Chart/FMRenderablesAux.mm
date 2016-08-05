//
//  FMRenderablesAux.m
//  FMChart
//
//  Created by Keisuke Mori on 2015/11/18.
//  Copyright © 2015 Keisuke Mori. All rights reserved.
//

#import "FMRenderablesAux.h"

#import "Engine.h"
#import "Buffers.h"
#import "FMProjections.h"
#import "CircleBuffers.h"
#import "Circles.h"

#include <memory>
#include <vector>
#include <tuple>
#include <algorithm>
#include <numeric>

@interface FMPieDoughnutDataProxy()

@property (nonatomic) std::vector<FMPieDoughnutDataProxyElement> buffer;

- (instancetype)initWithSeries:(FMPieDoughnutSeries *)series;

@end
@implementation FMPieDoughnutDataProxy

- (instancetype)initWithSeries:(FMPieDoughnutSeries *)series
{
	self = [super init];
	if(self) {
		_series = series;
		_buffer = std::vector<FMPieDoughnutDataProxyElement>();
	}
	return self;
}

- (FMPieDoughnutDataProxyElement *)elementWithID:(NSInteger)_id
{
	auto it = std::find_if(_buffer.begin(), _buffer.end(), [_id](const FMPieDoughnutDataProxyElement& e) {
		return (_id == e.dataID);
	});
	return (it != std::end(_buffer)) ? &(*it) : nil;
}

- (void)addElementWithValue:(CGFloat)value index:(uint32_t)index ID:(NSInteger)_id
{
	_buffer.emplace_back(_id, value, index);
}

- (void)removeElementWithID:(NSInteger)_id
{
	std::remove_if(_buffer.begin(), _buffer.end(), [_id](const FMPieDoughnutDataProxyElement &e) {
		return (_id == e.dataID);
	});
}

- (void)sort:(BOOL)ascend
{
	std::sort(std::begin(_buffer), std::end(_buffer), [ascend](const FMPieDoughnutDataProxyElement &a, const FMPieDoughnutDataProxyElement &b) {
		return ascend ? (b.value > a.value) : (b.value < a.value);
	});
}

- (void)clear
{
	_buffer.clear();
}

- (void)flush
{
	const CGFloat init = 0;
	const CGFloat total = std::accumulate(std::begin(_buffer), std::end(_buffer), init, [](const CGFloat &v, const FMPieDoughnutDataProxyElement& e) {
		return v + e.value;
	});
	const NSInteger count = _buffer.size();
	_series.count = count;
	if(count > 0) {
		CGFloat v = 0;
		const CGFloat coef = (2 * M_PI) / total;
		for(NSInteger i = 0; i < count; ++i) {
			const auto& e = _buffer[i];
			const CGFloat value = (v + e.value) * coef;
			[_series.values setValue:value index:e.index atIndex:i];
			v += e.value;
		}
	}
}

@end



@interface FMPieDoughnutSeries()

@end
@implementation FMPieDoughnutSeries

- (instancetype)initWithEngine:(FMEngine *)engine
						   arc:(FMContinuosArcPrimitive *)arc
					projection:(FMProjectionPolar *)projection
						values:(FMIndexedFloatBuffer *)values
	attributesCapacityOnCreate:(NSUInteger)attrCapacity
		valuesCapacityOnCreate:(NSUInteger)valueCapacity
{
	self = [super init];
	if(self) {
		_projection = projection;
		_arc = (arc) ? arc : [[FMContinuosArcPrimitive alloc] initWithEngine:engine
															   configuration:nil
																  attributes:nil
														  attributesCapacity:attrCapacity];
		
		_values = (values) ? values : [[FMIndexedFloatBuffer alloc] initWithResource:engine.resource
																			capacity:valueCapacity];
		_data = [[FMPieDoughnutDataProxy alloc] initWithSeries:self];
	}
	return self;
}

- (FMUniformArcConfiguration *)conf { return _arc.configuration; }
- (FMUniformArcAttributesArray *)attrs { return _arc.attributes; }
- (NSUInteger)capacity { return _values.capacity; }

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
			 chart:(FMMetalChart *)chart
{
	FMProjectionPolar *projection = _projection;
	const NSUInteger count = _count;
	const NSUInteger offset = _offset;
	if(projection && count > 0) {
		[_arc encodeWith:encoder projection:projection.projection values:_values offset:offset count:count];
	}
}

@end

