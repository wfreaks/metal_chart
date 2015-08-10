//
//  PolyLines.m
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/06.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "Lines.h"

@interface Line()

- (_Null_unspecified instancetype)initWithResource:(DeviceResource * _Nonnull)resource
											series:(id<Series> _Nonnull)series
											engine:(LineEngine * _Nonnull)engine
;

@end



@interface OrderedSeparatedLine()

@property (strong, nonatomic) OrderedSeries * _Nonnull orderedSeries;

@end



@interface OrderedPolyLine()

@property (strong, nonatomic) OrderedSeries * _Nonnull orderedSeries;

@end



@interface IndexedPolyLine()

@property (strong, nonatomic) IndexedSeries * _Nonnull indexedSeries;

@end




@implementation Line

- (instancetype)initWithResource:(DeviceResource *)resource
				series:(id<Series> _Nonnull)series
				engine:(LineEngine * _Nonnull)engine
{
    self = [super init];
    if(self) {
		_series = series;
		_engine = engine;
		_attributes = [[UniformLineAttributes alloc] initWithResource:resource];
    }
    return self;
}

- (void)encodeTo:(id<MTLCommandBuffer>)command
      renderPass:(MTLRenderPassDescriptor *)pass
      projection:(UniformProjection *)projection
{
    
}


- (void)setSampleData
{
	VertexBuffer *vertices = self.series.vertices;
	const NSUInteger vCount = vertices.capacity;
	for(int i = 0; i < vCount; ++i) {
		vertex_buffer *v = [vertices bufferAtIndex:i];
		const float range = 0.5;
		v->position.x = ((2 * ((i  ) % 2)) - 1) * range;
		v->position.y = ((2 * ((i/2) % 2)) - 1) * range;
	}
	self.series.info.offset = 0;
	
	[self setSampleAttributes];
}

- (void)setSampleAttributes
{
	UniformLineAttributes *attributes = self.attributes;
	[attributes setColorWithRed:1 green:1 blue:0 alpha:0.5];
	[attributes setWidth:3];
	[attributes setModifyAlphaOnEdge:YES];
	attributes.enableOverlay = YES;
}

static double gaussian() {
	const double u1 = (double)arc4random() / UINT32_MAX;
	const double u2 = (double)arc4random() / UINT32_MAX;
	const double f1 = sqrt(-2 * log(u1));
	const double f2 = 2 * M_PI * u2;
	return f1 * sin(f2);
}

- (void)appendSampleData:(NSUInteger)count
{
	VertexBuffer *vertices = self.series.vertices;
	const NSUInteger capacity = vertices.capacity;
	const NSUInteger idx_start = self.series.info.offset + self.series.info.count;
	for(NSUInteger i = 0; i < count; ++i) {
		vertex_buffer *v = [vertices bufferAtIndex:(idx_start+i)%capacity];
		v->position.x = idx_start + i;
		v->position.y = gaussian() * 0.5;
	}
}



@end

@implementation OrderedSeparatedLine

- (instancetype)initWithResource:(DeviceResource *)resource
				   orderedSeries:(OrderedSeries * _Nonnull)series
						  engine:(LineEngine * _Nonnull)engine
{
	self = [super initWithResource:resource series:series engine:engine];
	if(self) {
		_orderedSeries = series;
	}
	return self;
}

- (void)encodeTo:(id<MTLCommandBuffer>)command
	  renderPass:(MTLRenderPassDescriptor *)pass
	  projection:(UniformProjection *)projection
{
	[self.engine encodeTo:command
				pass:pass
			  vertex:self.series.vertices
			   index:nil
		  projection:projection
		  attributes:self.attributes
		  seriesInfo:self.series.info
		   separated:YES];
}

@end

@implementation OrderedPolyLine

- (instancetype)initWithResource:(DeviceResource *)resource
				   orderedSeries:(OrderedSeries * _Nonnull)series
						  engine:(LineEngine * _Nonnull)engine
{
	self = [super initWithResource:resource series:series engine:engine];
	if(self) {
		_orderedSeries = series;
	}
	return self;
}

- (void)encodeTo:(id<MTLCommandBuffer>)command
      renderPass:(MTLRenderPassDescriptor *)pass
      projection:(UniformProjection *)projection
{
    [self.engine encodeTo:command
                pass:pass
              vertex:self.series.vertices
               index:nil
          projection:projection
          attributes:self.attributes
          seriesInfo:self.series.info
		   separated:NO];
}

@end

@implementation IndexedPolyLine

- (instancetype)initWithResource:(DeviceResource *)resource
				   indexedSeries:(IndexedSeries * _Nonnull)series
						  engine:(LineEngine * _Nonnull)engine
{
	self = [super initWithResource:resource series:series engine:engine];
	if(self) {
		_indexedSeries = series;
	}
	return self;
}

- (void)encodeTo:(id<MTLCommandBuffer>)command
      renderPass:(MTLRenderPassDescriptor *)pass
      projection:(UniformProjection *)projection
          engine:(LineEngine *)engine
{
    [engine encodeTo:command
                pass:pass
              vertex:self.series.vertices
               index:self.indexedSeries.indices
          projection:projection
          attributes:self.attributes
          seriesInfo:self.series.info
		   separated:NO];
}

@end

