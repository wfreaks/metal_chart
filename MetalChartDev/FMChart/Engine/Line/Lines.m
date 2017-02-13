//
//  PolyLines.m
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/06.
//  Copyright © 2015 Keisuke Mori. All rights reserved.
//

#import "Lines.h"
#import <Metal/Metal.h>
#import "Buffers.h"
#import "Engine.h"
#import "Series.h"
#import "LineBuffers.h"
#import "Points.h"

@interface FMLinePrimitive()

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
;

- (id<MTLRenderPipelineState> _Nonnull)renderPipelineState;
- (NSUInteger)vertexCountWithCount:(NSUInteger)count;
- (NSString *)vertexFunctionName;
- (NSString *)fragmentFunctionName;
- (id<MTLBuffer>)attributesBuffer;

- (FMPointPrimitive * _Nullable)point;

@end




@implementation FMLinePrimitive

- (instancetype)initWithEngine:(FMEngine *)engine
{
	self = [super init];
	if(self) {
		_engine = engine;
		_configuration = [[FMUniformLineConf alloc] initWithResource:engine.resource];
	}
	return self;
}

- (id<MTLRenderPipelineState>)renderPipelineState
{
	id<MTLFunction> vertFunc = [_engine functionWithName:[self vertexFunctionName] library:nil];
	id<MTLFunction> fragFunc = [_engine functionWithName:[self fragmentFunctionName] library:nil];
	return [_engine pipelineStateWithVertFunc:vertFunc fragFunc:fragFunc writeDepth:YES];
}

- (id<MTLDepthStencilState>)depthState
{
	return _engine.depthState_depthGreater;
}

- (NSString *)vertexFunctionName { abort(); }
- (NSString *)fragmentFunctionName { abort(); }
- (id<MTLBuffer>)attributesBuffer { abort(); }

- (NSUInteger)vertexCountWithCount:(NSUInteger)count
{
	return 0;
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
		projection:(FMUniformProjectionCartesian2D *)projection
{
	id<FMSeries> const series = [self series];
	if(series) {
		id<MTLRenderPipelineState> renderState = [self renderPipelineState];
		id<MTLDepthStencilState> depthState = [self depthState];
		[encoder pushDebugGroup:@"DrawLine"];
		[encoder setRenderPipelineState:renderState];
		[encoder setDepthStencilState:depthState];
		
		id<MTLBuffer> vertexBuffer = [series vertexBuffer];
		id<MTLBuffer> attributes = [self attributesBuffer];
		id<MTLBuffer> confBuffer = _configuration.buffer;
		FMUniformSeriesInfo *info = series.info;

		[encoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];
		[encoder setVertexBuffer:confBuffer offset:0 atIndex:1];
		[encoder setVertexBuffer:attributes offset:0 atIndex:2];
		[encoder setVertexBuffer:projection.buffer offset:0 atIndex:3];
		[encoder setVertexBuffer:info.buffer offset:0 atIndex:4];
		
		[encoder setFragmentBuffer:confBuffer offset:0 atIndex:0];
		[encoder setFragmentBuffer:attributes offset:0 atIndex:1];
		[encoder setFragmentBuffer:projection.buffer offset:0 atIndex:2];
		
		NSUInteger count = [self vertexCountWithCount:info.count];
		if(count > 0) {
			const NSUInteger offset = 6 * (info.offset); // オフセットは折れ線かそうでないかに関係なく奇数を指定できると使いかたに幅が持たせられる.
			[encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:offset vertexCount:count];
		}
		
		FMPointPrimitive * point = [self point];
		if(point) {
			[point encodeWith:encoder projection:projection];
		}
		
		[encoder popDebugGroup];
	}
}

- (id<FMSeries>)series { return nil; }
- (FMPointPrimitive*)point { return nil; }

@end



@implementation FMPolyLinePrimitive

- (NSUInteger)vertexCountWithCount:(NSUInteger)count
{
	return 6 * MAX(0, ((NSInteger)(count-1)));
}

@end

@interface FMOrderedPolyLinePrimitive()

@property (nonatomic) FMOrderedPointPrimitive *point;

@end
@implementation FMOrderedPolyLinePrimitive

- (instancetype)initWithEngine:(FMEngine *)engine
				 orderedSeries:(FMOrderedSeries *)series
					attributes:(FMUniformLineAttributes * _Nullable)attributes
{
	self = [super initWithEngine:engine];
	if(self) {
		FMDeviceResource *resource = engine.resource;
		_attributes = (attributes) ? attributes : [[FMUniformLineAttributes alloc] initWithResource:resource];
		_series = series;
		[self.attributes setWidth:5.0];
		[self.attributes setColorVec:VectFromColor(0.3, 0.6, 0.8, 0.5)];
	}
	return self;
}

- (NSString *)vertexFunctionName { return @"PolyLineEngineVertexOrdered"; }

- (NSString *)fragmentFunctionName
{
	static NSString* names[] = {@"LineEngineFragment_Overlay", @"LineEngineFragment_NoOverlay", @"DashedLineFragment_Overlay", @"DashedLineFragment_NoOverlay"};
	NSInteger index = (self.configuration.enableDash ? 2 : 0) + (self.configuration.enableOverlay ? 0 : 1);
	return names[index];
}

- (id<MTLBuffer>)attributesBuffer { return _attributes.buffer; }

- (void)setSeries:(FMOrderedSeries *)series
{
	_series = series;
	self.point.series = series;
}

- (void)setPointAttributes:(FMUniformPointAttributes *)pointAttributes
{
	if(_pointAttributes != pointAttributes) {
		_pointAttributes = pointAttributes;
		if(pointAttributes) {
			_point = [[FMOrderedPointPrimitive alloc] initWithEngine:self.engine series:[self series] attributes:pointAttributes];
		} else {
			_point = nil;
		}
	}
}


@end





@interface FMOrderedAttributedPolyLinePrimitive()

@end
@implementation FMOrderedAttributedPolyLinePrimitive

- (instancetype)initWithEngine:(FMEngine *)engine
				 orderedSeries:(FMOrderedAttributedSeries *)series
			attributesCapacity:(NSUInteger)capacity
{
	self = [super initWithEngine:engine];
	if(self) {
		_attributesArray = [[FMUniformLineAttributesArray alloc] initWithResource:engine.resource capacity:capacity];
		_series = series;
	}
	return self;
}

- (NSString *)vertexFunctionName { return @"AttributedPolyLineEngineVertexOrdered"; }

- (NSString *)fragmentFunctionName
{
	return (self.configuration.enableOverlay) ? @"AttributedLineFragment_Overlay" : @"AttributedLineFragment_NoOverlay";
}

- (id<MTLBuffer>)attributesBuffer { return _attributesArray.buffer; }

@end






@interface FMAxisPrimitive()

@property (readonly, nonatomic) id<MTLBuffer> attributeBuffer;
@property (nonatomic, readonly) id<MTLRenderPipelineState> pipeline;

@end
@implementation FMAxisPrimitive

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
		_pipeline = [engine pipelineStateWithVertFunc:[engine functionWithName:@"AxisVertex" library:nil]
											 fragFunc:[engine functionWithName:@"AxisFragment" library:nil]
										   writeDepth:NO];
	}
	return self;
}

- (uniform_axis_attributes *)attributesAtIndex:(NSUInteger)index
{
	return ((uniform_axis_attributes *)[_attributeBuffer contents]) + index;
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
		projection:(FMUniformProjectionCartesian2D *)projection
{
	id<MTLRenderPipelineState> renderState = _pipeline;
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
	
	const NSUInteger maxCount = conf.maxMajorTicks;
	const NSUInteger lineCount = (1 + ((1 + conf.minorTicksPerMajor) * maxCount));
	const NSUInteger vertCount = 6 * lineCount;
	[encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:vertCount];
	
	[encoder popDebugGroup];
}

@end

@interface FMGridLinePrimitive()

@property (nonatomic, readonly) id<MTLRenderPipelineState> pipeline;

@end
@implementation FMGridLinePrimitive

- (instancetype)initWithEngine:(FMEngine *)engine
{
	self = [super init];
	if(self) {
		_configuration = [[FMUniformGridConfiguration alloc] initWithResource:engine.resource];
		_attributes = [[FMUniformGridAttributes alloc] initWithResource:engine.resource];
		_engine = engine;
		_pipeline = [engine pipelineStateWithVertFunc:[engine functionWithName:@"GridVertex" library:nil]
											 fragFunc:[engine functionWithName:@"GridFragment" library:nil]
										   writeDepth:YES];
		[_attributes setColorVec:VectFromColor(0.5, 0.5, 0.5, 0.8)];
		[_attributes setWidth:0.5];
		[_configuration setInterval:1];
		[_configuration setAnchorValue:0];
	}
	return self;
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
		projection:(FMUniformProjectionCartesian2D *)projection
		  maxCount:(NSUInteger)maxCount
{
	id<MTLRenderPipelineState> renderState = _pipeline;
	id<MTLDepthStencilState> depthState = _engine.depthState_depthGreater;
	if(renderState == nil){
		NSLog(@"render state is nil, returning...");
		return;
	}
	[encoder pushDebugGroup:@"DrawGridLine"];
	[encoder setRenderPipelineState:renderState];
	[encoder setDepthStencilState:depthState];
	
	id<MTLBuffer> attributesBuffer = self.attributes.buffer;
	id<MTLBuffer> configurationBuffer = self.configuration.buffer;
	
	[encoder setVertexBuffer:configurationBuffer offset:0 atIndex:0];
	[encoder setVertexBuffer:attributesBuffer offset:0 atIndex:1];
	[encoder setVertexBuffer:projection.buffer offset:0 atIndex:2];
	
	[encoder setFragmentBuffer:configurationBuffer offset:0 atIndex:0];
	[encoder setFragmentBuffer:attributesBuffer offset:0 atIndex:1];
	[encoder setFragmentBuffer:projection.buffer offset:0 atIndex:2];
	
	const NSUInteger vertCount = 6 * maxCount;
	[encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:vertCount];
	
	[encoder popDebugGroup];
}

@end


@interface FMOrderedPolyLineAreaPrimitive()

@property (nonatomic, readonly) id<MTLRenderPipelineState> pipeline;

@end

@implementation FMOrderedPolyLineAreaPrimitive

- (instancetype)initWithEngine:(FMEngine *)engine
				 orderedSeries:(FMOrderedSeries *)series
					attributes:(FMUniformLineAreaAttributes *)attributes
{
	self = [super init];
	if(self) {
		_engine = engine;
		_configuration = [[FMUniformLineAreaConfiguration alloc] initWithResource:engine.resource];
		_attributes = (attributes) ? attributes : [[FMUniformLineAreaAttributes alloc] initWithResource:engine.resource];
		_series = series;
		_pipeline = [engine pipelineStateWithVertFunc:[engine functionWithName:@"LineAreaVertex" library:nil]
											 fragFunc:[engine functionWithName:@"LineAreaFragment" library:nil]
										   writeDepth:NO];
	}
	return self;
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder projection:(FMUniformProjectionCartesian2D *)projection
{
	FMOrderedSeries *series = self.series;
	if(series) {
		id<MTLRenderPipelineState> renderState = _pipeline;
		id<MTLDepthStencilState> depthState = _engine.depthState_depthGreater;
		if(renderState == nil){
			NSLog(@"render state is nil, returning...");
			return;
		}
		[encoder pushDebugGroup:@"DrawPolyLineArea"];
		[encoder setRenderPipelineState:renderState];
		[encoder setDepthStencilState:depthState];
		
		id<MTLBuffer> attributesBuffer = self.attributes.buffer;
		id<MTLBuffer> configurationBuffer = self.configuration.buffer;
		
		[encoder setVertexBuffer:series.vertexBuffer offset:0 atIndex:0];
		[encoder setVertexBuffer:configurationBuffer offset:0 atIndex:1];
		[encoder setVertexBuffer:attributesBuffer offset:0 atIndex:2];
		[encoder setVertexBuffer:projection.buffer offset:0 atIndex:3];
		[encoder setVertexBuffer:series.info.buffer offset:0 atIndex:4];
		
		[encoder setFragmentBuffer:configurationBuffer offset:0 atIndex:0];
		[encoder setFragmentBuffer:attributesBuffer offset:0 atIndex:1];
		[encoder setFragmentBuffer:projection.buffer offset:0 atIndex:2];
		
		NSUInteger count = [self vertexCountWithCount:series.info.count];
		if(count > 0) {
			const NSUInteger offset = 6 * (series.info.offset);
			[encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:offset vertexCount:count];
		}
		
		[encoder popDebugGroup];
	}
}

- (NSUInteger)vertexCountWithCount:(NSUInteger)count
{
	return 6 * MAX(0, ((NSInteger)(count-1)));
}

@end

