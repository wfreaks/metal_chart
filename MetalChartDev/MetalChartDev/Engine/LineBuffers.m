//
//  LineBuffers.m
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/08/25.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "LineBuffers.h"
#import "Buffers.h"


@interface UniformLineAttributes()

@property (strong, nonatomic) id<MTLBuffer> buffer;

@end

@interface UniformAxisAttributes()

- (instancetype)initWithAttributes:(uniform_axis_attributes *)attr;

@end



@implementation UniformLineAttributes

- (id)initWithResource:(DeviceResource *)resource
{
    self = [super init];
    if(self) {
        _buffer = [resource.device newBufferWithLength:sizeof(uniform_line_attr) options:MTLResourceOptionCPUCacheModeWriteCombined];
    }
    return self;
}

- (uniform_line_attr *)attributes
{
    return (uniform_line_attr *)([self.buffer contents]);
}

- (void)setWidth:(CGFloat)width
{
    [self attributes]->width = (float)width;
}

- (void)setColorWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha
{
    [self attributes]->color = vector4(red, green, blue, alpha);
}

- (void)setModifyAlphaOnEdge:(BOOL)modify
{
    [self attributes]->modify_alpha_on_edge = (modify ? 1 : 0);
}

- (void)setEnableOverlay:(BOOL)enableOverlay
{
    _enableOverlay = enableOverlay;
    [self setModifyAlphaOnEdge:enableOverlay];
}

- (void)setLineLengthModifierStart:(float)start end:(float)end
{
    [self attributes]->length_mod = vector2(start, end);
}

- (void)setDepthValue:(float)depth
{
    [self attributes]->depth = depth;
}

@end



@implementation UniformAxisAttributes

- (instancetype)initWithAttributes:(uniform_axis_attributes *)attr
{
    self = [super init];
    if(self) {
        _attributes = attr;
        _attributes->length_mod = vector2((float)-1, (float)1);
    }
    return self;
}

- (void)setWidth:(float)width { _attributes->width = width; }

- (void)setLineLength:(float)length { _attributes->line_length = length; }

- (void)setColorWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha
{
    _attributes->color = vector4(red, green, blue, alpha);
}

- (void)setLengthModifierStart:(float)start end:(float)end
{
    _attributes->length_mod = vector2(start, end);
}

@end

@implementation UniformAxis

- (instancetype)initWithResource:(DeviceResource *)resource
{
    self = [super init];
    if(self) {
        id<MTLDevice> device = resource.device;
        _axisBuffer = [device newBufferWithLength:sizeof(uniform_axis) options:MTLResourceOptionCPUCacheModeWriteCombined];
        _attributeBuffer = [device newBufferWithLength:(sizeof(uniform_axis_attributes[3])) options:MTLResourceOptionCPUCacheModeWriteCombined];
        _axisAttributes = [[UniformAxisAttributes alloc] initWithAttributes:[self attributesAtIndex:0]];
        _majorTickAttributes = [[UniformAxisAttributes alloc] initWithAttributes:[self attributesAtIndex:1]];
        _minorTickAttributes = [[UniformAxisAttributes alloc] initWithAttributes:[self attributesAtIndex:2]];
    }
    return self;
}

- (uniform_axis *)axis {
    return (uniform_axis *)[_axisBuffer contents];
}

- (uniform_axis_attributes *)attributesAtIndex:(NSUInteger)index
{
    return ((uniform_axis_attributes *)[_attributeBuffer contents]) + index;
}

- (void)setAxisAnchorValue:(float)value
{
    if(_axisAnchorValue != value) {
        _axisAnchorValue = value;
        [self axis]->axis_anchor_value = value;
    }
}

- (void)setTickAnchorValue:(float)value
{
    if( _tickAnchorValue != value ) {
        _tickAnchorValue = value;
        [self axis]->tick_anchor_value = value;
    }
}

- (void)setMajorTickInterval:(float)interval
{
    if( _majorTickInterval != interval ) {
        _majorTickInterval = interval;
        [self axis]->tick_interval_major = interval;
    }
}

- (void)setDimensionIndex:(uint8_t)index
{
    [self axis]->dimIndex = index;
}

- (void)setMinorTicksPerMajor:(uint8_t)count {
    _minorTicksPerMajor = count;
    [self axis]->minor_ticks_per_major = count;
}

- (void)setMaxMajorTicks:(uint8_t)count {
    _maxMajorTicks = count;
    [self axis]->max_major_ticks = count;
}

@end



