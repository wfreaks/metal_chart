//
//  LineBuffers.m
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/08/25.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "LineBuffers.h"
#import "Buffers.h"


@interface FMUniformLineAttributes()

@property (strong, nonatomic) id<MTLBuffer> buffer;

@end

@implementation FMUniformLineAttributes

- (id)initWithResource:(FMDeviceResource *)resource
{
    self = [super init];
    if(self) {
        _buffer = [resource.device newBufferWithLength:sizeof(uniform_line_attr) options:MTLResourceCPUCacheModeWriteCombined];
        self.attributes->alpha = 1;
    }
    return self;
}

- (uniform_line_attr *)attributes
{
    return (uniform_line_attr *)([self.buffer contents]);
}

- (void)setWidth:(float)width
{
    [self attributes]->width = (float)width;
}

- (void)setColorRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha
{
    [self attributes]->color = vector4(red, green, blue, alpha);
}

- (void)setColor:(vector_float4)color
{
	[self attributes]->color = color;
}

- (void)setColorRef:(vector_float4 const *)color
{
    [self attributes]->color = *color;
}

- (void)setAlpha:(float)alpha
{
    [self attributes]->alpha = MIN(1.0f, MAX(0, alpha));
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

- (void)setDashLineLength:(float)length
{
    self.attributes->length_repeat = length;
}

- (void)setDashSpaceLength:(float)length
{
    self.attributes->length_space = length;
}

- (void)setDashLineAnchor:(float)anchor
{
    self.attributes->repeat_anchor_line = anchor;
}

- (void)setDashRepeatAnchor:(float)anchor
{
    self.attributes->repeat_anchor_dash = anchor;
}

@end



@implementation FMUniformAxisAttributes

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

- (void)setColorRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha
{
    _attributes->color = vector4(red, green, blue, alpha);
}

- (void)setColor:(vector_float4)color
{
    _attributes->color = color;
}

- (void)setColorRef:(const vector_float4 *)color
{
	_attributes->color = *color;
}

- (void)setLengthModifierStart:(float)start end:(float)end
{
    _attributes->length_mod = vector2(start, end);
}

@end

@implementation FMUniformAxisConfiguration

static const float _ndc_anchor_invalid = 8;

- (instancetype)initWithResource:(FMDeviceResource *)resource
{
    self = [super init];
    if(self) {
        id<MTLDevice> device = resource.device;
        _buffer = [device newBufferWithLength:sizeof(uniform_axis_configuration) options:MTLResourceOptionCPUCacheModeWriteCombined];
    }
    return self;
}

- (uniform_axis_configuration *)configuration {
    return (uniform_axis_configuration *)[_buffer contents];
}

- (void)setAxisAnchorDataValue:(float)value
{
    if(_axisAnchorDataValue != value) {
        _axisAnchorDataValue = value;
        self.configuration->axis_anchor_value_data = value;
    }
    self.axisAnchorNDCValue = _ndc_anchor_invalid;
}

- (void)setAxisAnchorNDCValue:(float)value
{
    if(_axisAnchorNDCValue != value) {
        _axisAnchorNDCValue = value;
        self.configuration->axis_anchor_value_ndc = value;
    }
}

- (void)setTickAnchorValue:(float)value
{
    if( _tickAnchorValue != value ) {
        _tickAnchorValue = value;
        _majorTickValueModified = YES;
        self.configuration->tick_anchor_value = value;
    }
}

- (void)setMajorTickInterval:(float)interval
{
    if( _majorTickInterval != interval ) {
        _majorTickInterval = interval;
        _majorTickValueModified = YES;
        self.configuration->tick_interval_major = interval;
#ifdef DEBUG
        NSAssert(interval > 0, @"interval should be positive (may work in some cases, but there's no guarantee)");
#endif
    }
}

- (void)setDimensionIndex:(uint8_t)index
{
    if( _dimensionIndex != index ) {
        _dimensionIndex = index;
        self.configuration->dimIndex = index;
    }
}

- (void)setMinorTicksPerMajor:(uint8_t)count {
    _minorTicksPerMajor = count;
    self.configuration->minor_ticks_per_major = count;
}

- (void)setMaxMajorTicks:(uint8_t)count {
    _maxMajorTicks = count;
    self.configuration->max_major_ticks = count;
}

- (BOOL)checkIfMajorTickValueModified:(BOOL (^)(FMUniformAxisConfiguration *))ifModified
{
    const BOOL isModified = _majorTickValueModified;
    if(isModified) {
        _majorTickValueModified = ! ifModified(self);
    }
    return isModified;
}

- (float)axisAnchorValueWithProjection:(FMUniformProjectionCartesian2D *)projection
{
    if(_axisAnchorNDCValue != _ndc_anchor_invalid) {
        const BOOL isx = (_dimensionIndex == 0); // これは軸の方向、必要なのは直交する方向の位置.
        const CGSize scale = projection.valueScale;
        const CGPoint offset = projection.valueOffset; // offsetは描画時のそれで符合反転している事に注意.
        return (isx) ? (scale.height * _axisAnchorNDCValue) - offset.y : (scale.width * _axisAnchorNDCValue) - offset.x;
    }
    return _axisAnchorDataValue;
}

@end



@implementation FMUniformGridAttributes

- (instancetype)initWithResource:(FMDeviceResource *)resource
{
    self = [super init];
    if(self) {
        _buffer = [resource.device newBufferWithLength:sizeof(uniform_grid_attributes) options:MTLResourceOptionCPUCacheModeWriteCombined];
    }
    return self;
}

- (uniform_grid_attributes *)attributes { return (uniform_grid_attributes *)[_buffer contents]; }

- (void)setWidth:(float)width
{
    self.attributes->width = width;
}

- (void)setColorRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha
{
    self.attributes->color = vector4(red, green, blue, alpha);
}

- (void)setColor:(vector_float4)color
{
    self.attributes->color = color;
}

- (void)setColorRef:(const vector_float4 *)color
{
	self.attributes->color = *color;
}

- (void)setAnchorValue:(float)anchorValue
{
    if(_anchorValue != anchorValue) {
        _anchorValue = anchorValue;
        self.attributes->anchor_value = anchorValue;
    }
}

- (void)setInterval:(float)interval
{
    if(_interval != interval) {
        _interval = interval;
        self.attributes->interval = interval;
    }
}

- (void)setDimensionIndex:(uint8_t)dimensionIndex
{
    _dimensionIndex = dimensionIndex;
    self.attributes->dimIndex = dimensionIndex;
}

- (void)setDepthValue:(float)depth
{
    self.attributes->depth = depth;
}

- (void)setDashLineLength:(float)length
{
    self.attributes->length_repeat = length;
}

- (void)setDashSpaceLength:(float)length
{
    self.attributes->length_space = length;
}

- (void)setDashLineAnchor:(float)anchor
{
    self.attributes->repeat_anchor_line = anchor;
}

- (void)setDashRepeatAnchor:(float)anchor
{
    self.attributes->repeat_anchor_dash = anchor;
}

@end

