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

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
									  attributes:(FMUniformLineAttributes * _Nullable)attributes
;

- (id<MTLRenderPipelineState> _Nonnull)renderPipelineStateWithProjection:(FMUniformProjectionCartesian2D * _Nonnull)projection;
- (NSUInteger)vertexCountWithCount:(NSUInteger)count;
- (id<MTLBuffer> _Nullable)indexBuffer;
- (NSString *)vertexFunctionName;
- (NSString *)fragmentFunctionName;

@end




@implementation LinePrimitive

- (instancetype)initWithEngine:(FMEngine *)engine
					attributes:(FMUniformLineAttributes *)attributes
{
    self = [super init];
    if(self) {
		FMDeviceResource *resource = engine.resource;
		_engine = engine;
		_attributes = (attributes) ? attributes : [[FMUniformLineAttributes alloc] initWithResource:resource];
    }
    return self;
}

- (id<MTLRenderPipelineState>)renderPipelineStateWithProjection:(FMUniformProjectionCartesian2D *)projection
{
	return [_engine pipelineStateWithProjection:projection vertFunc:[self vertexFunctionName] fragFunc:[self fragmentFunctionName] writeDepth:YES];
}

- (id<MTLDepthStencilState>)depthState
{
	return _engine.depthState_depthGreater;
}

- (NSString *)vertexFunctionName
{
	abort();
}

- (NSString *)fragmentFunctionName
{
    static NSString* names[] = {@"LineEngineFragment_Overlay", @"LineEngineFragment_NoOverlay", @"DashedLineFragment_Overlay", @"DashedLineFragment_NoOverlay"};
    NSInteger index = (self.attributes.enableDash ? 2 : 0) + (self.attributes.enableOverlay ? 0 : 1);
    return names[index];
}

- (NSUInteger)vertexCountWithCount:(NSUInteger)count
{
	return 0;
}

- (id<MTLBuffer>)indexBuffer { return nil; }

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
		projection:(FMUniformProjectionCartesian2D *)projection
{
	id<Series> const series = [self series];
	if(series) {
		id<MTLRenderPipelineState> renderState = [self renderPipelineStateWithProjection:projection];
		id<MTLDepthStencilState> depthState = [self depthState];
		[encoder pushDebugGroup:@"DrawLine"];
		[encoder setRenderPipelineState:renderState];
		[encoder setDepthStencilState:depthState];
		
		id<MTLBuffer> vertexBuffer = [series vertexBuffer];
		id<MTLBuffer> indexBuffer = [self indexBuffer];
		FMUniformLineAttributes *attributes = _attributes;
		FMUniformSeriesInfo *info = series.info;

		[encoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];
		[encoder setVertexBuffer:indexBuffer offset:0 atIndex:1];
		[encoder setVertexBuffer:projection.buffer offset:0 atIndex:2];
		[encoder setVertexBuffer:attributes.buffer offset:0 atIndex:3];
		[encoder setVertexBuffer:info.buffer offset:0 atIndex:4];
		
		[encoder setFragmentBuffer:projection.buffer offset:0 atIndex:0];
		[encoder setFragmentBuffer:attributes.buffer offset:0 atIndex:1];
		
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

- (id<Series>)series { return nil; }

- (void)setPointAttributes:(FMUniformPointAttributes *)pointAttributes
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

- (instancetype)initWithEngine:(FMEngine *)engine
				orderedSeries:(FMOrderedSeries *)series
					attributes:(FMUniformLineAttributes * _Nullable)attributes
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

- (PointPrimitive *)createPointPrimitiveWithAttributes:(FMUniformPointAttributes *)attributes
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

- (instancetype)initWithEngine:(FMEngine *)engine
				 orderedSeries:(FMOrderedSeries *)series
					attributes:(FMUniformLineAttributes * _Nullable)attributes
{
	self = [super initWithEngine:engine attributes:attributes];
	if(self) {
		_series = series;
		[self.attributes setWidth:5.0];
		[self.attributes setColorWithRed:0.3 green:0.6 blue:0.8 alpha:0.5];
	}
	return self;
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

- (void)setSeries:(FMOrderedSeries *)series
{
	_series = series;
	self.point.series = series;
}

@end

@interface Axis()

@property (readonly, nonatomic) id<MTLBuffer> attributeBuffer;

@end

@implementation Axis

- (instancetype)initWithEngine:(FMEngine *)engine
{
    self = [super init];
    if(self) {
        _engine = engine;
        _configuration = [[FMUniformAxisConfiguration alloc] initWithResource:engine.resource];
        _attributeBuffer = [engine.resource.device newBufferWithLength:(sizeof(uniform_axis_attributes[3])) options:MTLResourceOptionCPUCacheModeWriteCombined];
        _axisAttributes = [[FMUniformAxisAttributes alloc] initWithAttributes:[self attributesAtIndex:0]];
        _majorTickAttributes = [[FMUniformAxisAttributes alloc] initWithAttributes:[self attributesAtIndex:1]];
        _minorTickAttributes = [[FMUniformAxisAttributes alloc] initWithAttributes:[self attributesAtIndex:2]];
    }
    return self;
}

- (uniform_axis_attributes *)attributesAtIndex:(NSUInteger)index
{
    return ((uniform_axis_attributes *)[_attributeBuffer contents]) + index;
}


- (id<MTLRenderPipelineState>)renderPipelineStateWithProjection:(FMUniformProjectionCartesian2D *)projection
{
    return [_engine pipelineStateWithProjection:projection
                                       vertFunc:@"AxisVertex"
                                       fragFunc:@"AxisFragment"
                                     writeDepth:NO];
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
        projection:(FMUniformProjectionCartesian2D *)projection
     maxMajorTicks:(NSUInteger)maxCount
{
    id<MTLRenderPipelineState> renderState = [self renderPipelineStateWithProjection:projection];
    id<MTLDepthStencilState> depthState = _engine.depthState_noDepth;
    if(renderState == nil){
        NSLog(@"render state is nil, returning...");
        return;
    }
    [encoder pushDebugGroup:@"DrawAxis"];
    [encoder setRenderPipelineState:renderState];
    [encoder setDepthStencilState:depthState];
    
	FMUniformAxisConfiguration *const conf = _configuration;
    id<MTLBuffer> attributesBuffer = _attributeBuffer;
    
    [encoder setVertexBuffer:conf.buffer offset:0 atIndex:0];
    [encoder setVertexBuffer:attributesBuffer offset:0 atIndex:1];
    [encoder setVertexBuffer:projection.buffer offset:0 atIndex:2];
    
    [encoder setFragmentBuffer:attributesBuffer offset:0 atIndex:0];
	[encoder setFragmentBuffer:projection.buffer offset:0 atIndex:1];
    
    const NSUInteger lineCount = (1 + ((1 + conf.minorTicksPerMajor) * maxCount));
    const NSUInteger vertCount = 6 * lineCount;
    conf.maxMajorTicks = maxCount;
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:vertCount];
    
    [encoder popDebugGroup];
}

@end


@implementation GridLine

- (instancetype)initWithEngine:(FMEngine *)engine
{
    self = [super init];
    if(self) {
        _attributes = [[FMUniformGridAttributes alloc] initWithResource:engine.resource];
        _engine = engine;
        [_attributes setColorWithRed:0.5 green:0.5 blue:0.5 alpha:0.8];
        [_attributes setWidth:0.5];
        [_attributes setInterval:1];
        [_attributes setAnchorValue:0];
    }
    return self;
}

- (id<MTLRenderPipelineState>)renderPipelineStateWithProjection:(FMUniformProjectionCartesian2D *)projection
{
    return [_engine pipelineStateWithProjection:projection
                                       vertFunc:@"GridVertex"
                                       fragFunc:@"GridFragment"
                                     writeDepth:YES
            ];
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
        projection:(FMUniformProjectionCartesian2D *)projection
          maxCount:(NSUInteger)maxCount
{
    id<MTLRenderPipelineState> renderState = [self renderPipelineStateWithProjection:projection];
    id<MTLDepthStencilState> depthState = _engine.depthState_depthGreater;
    if(renderState == nil){
        NSLog(@"render state is nil, returning...");
        return;
    }
    [encoder pushDebugGroup:@"DrawGridLine"];
    [encoder setRenderPipelineState:renderState];
    [encoder setDepthStencilState:depthState];
    
    FMUniformGridAttributes *const attr = self.attributes;
    id<MTLBuffer> attributesBuffer = attr.buffer;
    
    [encoder setVertexBuffer:attributesBuffer offset:0 atIndex:0];
    [encoder setVertexBuffer:projection.buffer offset:0 atIndex:1];
    
    [encoder setFragmentBuffer:attributesBuffer offset:0 atIndex:0];
    [encoder setFragmentBuffer:projection.buffer offset:0 atIndex:1];
    
    const NSUInteger vertCount = 6 * maxCount;
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:vertCount];
    
    [encoder popDebugGroup];
}

@end

