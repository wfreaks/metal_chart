//
//  PolyLines.m
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/06.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "Lines.h"
#import <Metal/Metal.h>
#import "Buffers.h"
#import "Engine.h"
#import "Series.h"
#import "LineBuffers.h"
#import "Points.h"

@interface LinePrimitive()

@property (strong, nonatomic) DynamicPointPrimitive * _Nullable point;

- (instancetype _Null_unspecified)initWithEngine:(Engine * _Nonnull)engine
									  attributes:(UniformLineAttributes * _Nullable)attributes
;

- (id<MTLRenderPipelineState> _Nonnull)renderPipelineStateWithProjection:(UniformProjection * _Nonnull)projection;
- (NSUInteger)vertexCountWithCount:(NSUInteger)count;
- (id<MTLBuffer> _Nullable)indexBuffer;
- (NSString *)vertexFunctionName;
- (NSString *)fragmentFunctionName;

@end




@implementation LinePrimitive

- (instancetype)initWithEngine:(Engine *)engine
					attributes:(UniformLineAttributes *)attributes
{
    self = [super init];
    if(self) {
		DeviceResource *resource = engine.resource;
		_engine = engine;
		_attributes = (attributes) ? attributes : [[UniformLineAttributes alloc] initWithResource:resource];
    }
    return self;
}

- (id<MTLRenderPipelineState>)renderPipelineStateWithProjection:(UniformProjection *)projection
{
	return [_engine pipelineStateWithProjection:projection vertFunc:[self vertexFunctionName] fragFunc:[self fragmentFunctionName]];
}

- (id<MTLDepthStencilState>)depthState
{
	return _attributes.enableOverlay ? _engine.depthState_noDepth : _engine.depthState_writeDepth;
}

- (NSString *)vertexFunctionName
{
	abort();
}

- (NSString *)fragmentFunctionName
{
	return _attributes.enableOverlay ? @"LineEngineFragment_NoDepth" : @"LineEngineFragment_WriteDepth";
}

- (NSUInteger)vertexCountWithCount:(NSUInteger)count
{
	return 0;
}

- (id<MTLBuffer>)indexBuffer { return nil; }

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
		projection:(UniformProjection *)projection
{
	id<Series> const series = [self series];
	if(series) {
		id<MTLRenderPipelineState> renderState = [self renderPipelineStateWithProjection:projection];
		id<MTLDepthStencilState> depthState = [self depthState];
		[encoder pushDebugGroup:@"DrawLine"];
		[encoder setRenderPipelineState:renderState];
		[encoder setDepthStencilState:depthState];
		
		const CGSize ps = projection.physicalSize;
		const RectPadding pr = projection.padding;
		const CGFloat scale = projection.screenScale;
		if(projection.enableScissor) {
			MTLScissorRect rect = {pr.left*scale, pr.top*scale, (ps.width-(pr.left+pr.right))*scale, (ps.height-(pr.bottom+pr.top))*scale};
			[encoder setScissorRect:rect];
		} else {
			MTLScissorRect rect = {0, 0, ps.width * scale, ps.height * scale};
			[encoder setScissorRect:rect];
		}
		
		id<MTLBuffer> vertexBuffer = [series vertexBuffer];
		id<MTLBuffer> indexBuffer = [self indexBuffer];
		UniformLineAttributes *attributes = _attributes;
		UniformSeriesInfo *info = series.info;

		[encoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];
		[encoder setVertexBuffer:indexBuffer offset:0 atIndex:1];
		[encoder setVertexBuffer:projection.buffer offset:0 atIndex:2];
		[encoder setVertexBuffer:attributes.buffer offset:0 atIndex:3];
		[encoder setVertexBuffer:info.buffer offset:0 atIndex:4];
		
		[encoder setFragmentBuffer:projection.buffer offset:0 atIndex:0];
		[encoder setFragmentBuffer:attributes.buffer offset:0 atIndex:1];
		
	//	const NSUInteger count = 6 * MAX(0, ((NSInteger)(separated ? (info.count/2) : info.count-1))); // 折れ線でない場合、線数は半分になる、それ以外は-1.４点を結んだ場合を想像するとわかる. この線数に６倍すると頂点数.
		NSUInteger count = [self vertexCountWithCount:info.count];
		if(count > 0) {
			const NSUInteger offset = 6 * (info.offset); // オフセットは折れ線かそうでないかに関係なく奇数を指定できると使いかたに幅が持たせられる.
			[encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:offset vertexCount:count];
		}
		
		PointPrimitive *point = [self point];
		if(point) {
			[point encodeWith:encoder projection:projection];
		}
		
		[encoder popDebugGroup];
	}
}

- (void)setSampleAttributes
{
	UniformLineAttributes *attributes = self.attributes;
	[attributes setColorWithRed:0.3 green:0.6 blue:0.8 alpha:0.5];
	[attributes setWidth:2];
	attributes.enableOverlay = NO;
}

- (id<Series>)series { return nil; }

- (void)setPointAttributes:(UniformPoint *)pointAttributes
{
	if(_pointAttributes != pointAttributes) {
		_pointAttributes = pointAttributes;
		if(pointAttributes) {
			_point = [[DynamicPointPrimitive alloc] initWithEngine:_engine series:[self series] attributes:pointAttributes];
		} else {
			_point = nil;
		}
	}
}

@end

@implementation OrderedSeparatedLinePrimitive

- (instancetype)initWithEngine:(Engine *)engine
				orderedSeries:(OrderedSeries *)series
					attributes:(UniformLineAttributes * _Nullable)attributes
{
	self = [super initWithEngine:engine attributes:attributes];
	if(self) {
		_series = series;
	}
	return self;
}

- (NSUInteger)vertexCountWithCount:(NSUInteger)count
{
	return 6 * MAX(0, ((NSInteger)(count/2)));
}

- (NSString *)vertexFunctionName { return @"SeparatedLineEngineVertexOrdered"; }

- (PointPrimitive *)createPointPrimitiveWithAttributes:(UniformPoint *)attributes
{
	return [[OrderedPointPrimitive alloc] initWithEngine:self.engine series:_series attributes:attributes];
}

@end

@implementation PolyLinePrimitive

- (NSUInteger)vertexCountWithCount:(NSUInteger)count
{
	return 6 * MAX(0, ((NSInteger)(count-1)));
}

@end

@implementation OrderedPolyLinePrimitive

- (instancetype)initWithEngine:(Engine *)engine
				 orderedSeries:(OrderedSeries *)series
					attributes:(UniformLineAttributes * _Nullable)attributes
{
	self = [super initWithEngine:engine attributes:attributes];
	if(self) {
		_series = series;
	}
	return self;
}

- (void)setSampleData
{
	VertexBuffer *vertices = _series.vertices;
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

static double gaussian(double mean, double variance) {
	const double u1 = (double)arc4random() / UINT32_MAX;
	const double u2 = (double)arc4random() / UINT32_MAX;
	const double f1 = sqrt(-2 * log(u1));
	const double f2 = 2 * M_PI * u2;
	return (variance * f1 * sin(f2)) + mean;
}

- (void)appendSampleData:(NSUInteger)count
		  maxVertexCount:(NSUInteger)maxCount
                    mean:(CGFloat)mean
                variance:(CGFloat)variant
			  onGenerate:(void (^ _Nullable)(float, float))block
{
	VertexBuffer *vertices = _series.vertices;
	const NSUInteger capacity = vertices.capacity;
	const NSUInteger idx_start = self.series.info.offset + self.series.info.count;
	const NSUInteger idx_end = idx_start + count;
	for(NSUInteger i = 0; i < count; ++i) {
		vertex_buffer *v = [vertices bufferAtIndex:(idx_start+i)%capacity];
		const float x = idx_start + i;
		const float y = gaussian(mean, variant);
		v->position.x = x;
		v->position.y = y;
		if(block) {
			block(x, y);
		}
	}
	const NSUInteger vCount = MIN(capacity, MIN(maxCount, idx_end));
	self.series.info.count = vCount;
	self.series.info.offset = idx_end - vCount;
}

- (NSString *)vertexFunctionName { return @"PolyLineEngineVertexOrdered"; }

- (void)setSeries:(OrderedSeries *)series
{
	_series = series;
	self.point.series = series;
}

@end

@implementation IndexedPolyLinePrimitive

- (instancetype)initWithEngine:(Engine *)engine
				 indexedSeries:(IndexedSeries *)series
					attributes:(UniformLineAttributes * _Nullable)attributes
{
	self = [super initWithEngine:engine attributes:attributes];
	if(self) {
		_series = series;
	}
	return self;
}

- (id<MTLBuffer>)indexBuffer
{
	return _series.indices.buffer;
}

- (NSString *)vertexFunctionName { return @"PolyLineEngineVertexIndexed"; }

- (void)setSeries:(IndexedSeries *)series
{
	_series = series;
	self.point.series = series;
}

@end

@implementation Axis

- (instancetype)initWithEngine:(Engine *)engine
{
    self = [super init];
    if(self) {
        _engine = engine;
        _attributes = [[UniformAxisConfiguration alloc] initWithResource:engine.resource];
    }
    return self;
}

- (id<MTLRenderPipelineState>)renderPipelineStateWithProjection:(UniformProjection *)projection
{
    return [_engine pipelineStateWithProjection:projection
                                       vertFunc:@"AxisVertex"
                                       fragFunc:@"AxisFragment"];
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
        projection:(UniformProjection *)projection
{
    id<MTLRenderPipelineState> renderState = [self renderPipelineStateWithProjection:projection];
    id<MTLDepthStencilState> depthState = _engine.depthState_noDepth;
    [encoder pushDebugGroup:@"DrawAxis"];
    [encoder setRenderPipelineState:renderState];
    [encoder setDepthStencilState:depthState];
    
    const CGSize ps = projection.physicalSize;
    const CGFloat scale = projection.screenScale;
    MTLScissorRect rect = {0, 0, ps.width * scale, ps.height * scale};
    [encoder setScissorRect:rect];
	
	UniformAxisConfiguration *const attributes = _attributes;
    
    [encoder setVertexBuffer:attributes.axisBuffer offset:0 atIndex:0];
    [encoder setVertexBuffer:attributes.attributeBuffer offset:0 atIndex:1];
    [encoder setVertexBuffer:projection.buffer offset:0 atIndex:2];
    
    [encoder setFragmentBuffer:attributes.attributeBuffer offset:0 atIndex:0];
	[encoder setFragmentBuffer:projection.buffer offset:0 atIndex:1];
    
    const NSUInteger lineCount = (1 + ((1+attributes.minorTicksPerMajor) * attributes.maxMajorTicks));
    const NSUInteger vertCount = 6 * lineCount;
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:vertCount];
    
    [encoder popDebugGroup];
}

@end

