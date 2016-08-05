//
//  LineBuffers.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/25.
//  Copyright © 2015 Keisuke Mori. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import "Line_common.h"
#import "Buffers.h"

@protocol MTLBuffer;


/**
 * A wrapper class for struct uniform_line_attr that provides setter methods.
 * width is in logical pixel and represents distance from the edge to the other.
 * color vector is in RGBA format.
 *
 * dashLineLength and dashSpaceLength determine shape of dashed line segments and intervals.
 * their length (logical pixel) are defined by (width * length).
 * dashLineLength with value +FLOAT_MIN will result in dot line, and 1 in stroke of length that equals to width.
 * dashSpaceLength with value +FLOAT_MIN will put two segments almost in contact, and 1 in interval of length that equals to width.
 *
 * dashLineAnchor and dashRepeatAnchor specifies 'the anchor point of the whole line(all segments and space)' and
 * 'the anchor point of the repeat unit of semgent and space' which overlap each other.
 * dashLineAnchor with vaue -1 place the anchor at the beginning of the whole line, and 0 at the center.
 * dashRepeatAnchor with value -1 or +1 place the anchor at the middle of interval, and 0 at the middle of the segment.
 */

@interface FMUniformLineAttributes : FMAttributesBuffer

@property (readonly, nonatomic) uniform_line_attr * _Nonnull attributes;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
                                     size:(NSUInteger)size
UNAVAILABLE_ATTRIBUTE;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource;

/**
 * sets the line width (from the edge to the other) in logical pixel.
 */
- (void)setWidth:(float)width;

- (void)setColor:(UIColor *_Nonnull)color;
- (void)setColorVec:(vector_float4)color;
- (void)setColorVecRef:(const vector_float4 *_Nonnull)color;
- (void)setColorRed:(float)r green:(float)g blue:(float)b alpha:(float)a;

- (void)setDashLineLength:(float)length;
- (void)setDashSpaceLength:(float)length;

- (void)setDashLineAnchor:(float)anchor;
- (void)setDashRepeatAnchor:(float)anchor;

@end


/**
 * See FMAttributesArray, FMArrayBuffer and FMUniformLineAttributes for details.
 */

@interface FMUniformLineAttributesArray : FMAttributesArray<FMUniformLineAttributes*>

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
								 capacity:(NSUInteger)capacity
NS_DESIGNATED_INITIALIZER;

@end



/**
 * A wrapper class for struct uniform_line_conf that provides setter methods.
 * 
 * alpha must be in range [0, 1], behavior is undefined otherwise.
 * if enableDash is set to YES, then properties for dashed line will be active (loads of the fragment shader will be somewhat increased).
 * enableOverlay controls anti-aliasing quality and drawing result of polylines with translucent color.
 * (if set to YES, line edge will be less juggy, but its joints will be rendered multiple times with a given color due to disabled depth test)
 */

@interface FMUniformLineConf : NSObject

@property (readonly, nonatomic) id<MTLBuffer> _Nonnull buffer;
@property (readonly, nonatomic) uniform_line_conf * _Nonnull conf;

/**
 * default NO.
 */
@property (assign, nonatomic) BOOL enableDash;

/**
 * default NO.
 */
@property (assign, nonatomic) BOOL enableOverlay;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource;

- (void)setAlpha:(float)alpha;

- (void)setDepthValue:(float)depth;

@end


/**
 * FMUniformAxisAttributes is a wrapper class for struct uniform_axis_attributes that provides setter methods.
 * An instance of this class applies to axis and major/minor ticks.
 * Interpretations of width and colors are equivalent to those of FMUniformLineAttribuutes.
 *
 * lineLength controls ticks length (from center to the edge) in logical pixel.
 * lengthModifier (a, b) modifies length of (begin-center) and (center-end) separately.
 * ( (-1, 1) -> b--c--e, (-1, 0) -> b--ce, (0, 2) -> bc----e )
 */

@interface FMUniformAxisAttributes : NSObject

@property (readonly, nonatomic) uniform_axis_attributes * _Nonnull attributes;

- (instancetype _Nonnull)initWithAttributes:(uniform_axis_attributes * _Nonnull)attr;

- (void)setWidth:(float)width;

- (void)setColor:(UIColor *_Nonnull)color;
- (void)setColorVec:(vector_float4)color;
- (void)setColorVecRef:(const vector_float4 *_Nonnull)color;
- (void)setColorRed:(float)r green:(float)g blue:(float)b alpha:(float)a;

- (void)setLineLength:(float)length;

- (void)setLengthModifierStart:(float)start end:(float)end;
- (void)setLengthModifierStart:(float)start;
- (void)setLengthModifierEnd:(float)end;

@end

// 他のUniform系と異なりほとんどがreadableなプロパティで定義されているのは、
// Attributeと違い設定はCPU側で参照される事が多いためである。
// CPU/GPU共有バッファは出来れば書き込み専用にしたいので、プロパティへのミラーリングをしている.

/**
 * FMUniformAxisConfiguration is a wrapper class for struct uniform_axis_configuration that provides setter methods.
 * An axis has a signle FMUniformAxisConfiguration instance.
 *
 * axisDataValue controls on which value an axis placed in the 'orthogonal dimension' (where y axis is placed in x dim).
 * axisAnchorNDCValue controls specifies an axis position in ndc if in range [-1, 1], axisDataValue will be used otherwise.
 * tickAnchorValue specifies from where tick series starts (including negative-indixed ticks) in the dimension alongside.
 * majorTickInterval specifies interval between each tick in the dimension alongside.
 * minorTicksPerMajor specifies how many minor ticks drawn per a major tick.
 * (note that the value 1 will results in overlapped major/minor ticks and none other than that)
 *
 * dimensionIndex is the index of the dimension an axis belongs to (0 for x axis, 1 for y axis).
 *
 * maxMajorTicks limit the count how many major ticks can be on screen at once (to reduce gpu workload).
 * maxMajorTicks property is not for FMAxis class (FMAxis calcute and set the value, and FMAxisLabel and FMGridLine use it)
 *
 * majorTickValueModified shows that the properties which affetcts tick values have been modified.
 * the flag will be set to NO when checkIfMajorTickValueModified: is called with blocks returning YES.
 * (purpose of the property and the method is to check if rendering cache of labels should be invalidated or not).
 */

@interface FMUniformAxisConfiguration : NSObject

@property (readonly, nonatomic) id<MTLBuffer> _Nonnull buffer;
@property (readonly, nonatomic) uniform_axis_configuration * _Nonnull configuration;

@property (assign  , nonatomic) float axisAnchorDataValue;
@property (assign  , nonatomic) float axisAnchorNDCValue; // [-1, 1], この値の外ではDataValueが使われる
@property (assign  , nonatomic) float tickAnchorValue;
@property (assign  , nonatomic) float majorTickInterval;
@property (assign  , nonatomic) uint8_t minorTicksPerMajor;

@property (assign  , nonatomic) uint8_t dimensionIndex;
@property (assign  , nonatomic) uint8_t maxMajorTicks;

@property (readonly, nonatomic) BOOL majorTickValueModified;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource;

/**
 * check and modify the flag which shows render cache of labels should be invalidated or not.
 * if the flag is YES, then ifModified will be executed, and then clear the flag only if its return value is YES.
 * returns old value of the flag regardless of results of flag modification.
 * passing an nil block will cause EXC_BAD_ACCESS.
 */
- (BOOL)checkIfMajorTickValueModified:(BOOL (^_Nonnull)(FMUniformAxisConfiguration *_Nonnull))ifModified;

/**
 * returns the value of an axis position (to resolve conflict of axisAnchorDataValue and axisAnchorNDCValue)
 */
- (float)axisAnchorValueWithProjection:(FMUniformProjectionCartesian2D * _Nonnull)projection;

@end


/**
 * FMUniformGridAttributes is a wrapper for struct unifim_gird_attributes that provides setter methods.
 * 
 * Interpretations of width, color, dashing attributes, anchorValue, interval are equivalent to those of FMUniformAxisAttributes.
 */

@interface FMUniformGridAttributes : NSObject

@property (readonly, nonatomic) id<MTLBuffer> _Nonnull buffer;
@property (readonly, nonatomic) uniform_grid_attributes * _Nonnull attributes;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

- (void)setWidth:(float)width;

- (void)setColor:(UIColor *_Nonnull)color;
- (void)setColorVec:(vector_float4)color;
- (void)setColorVecRef:(const vector_float4 *_Nonnull)color;
- (void)setColorRed:(float)r green:(float)g blue:(float)b alpha:(float)a;

- (void)setDashLineLength:(float)length;

- (void)setDashSpaceLength:(float)length;

- (void)setDashLineAnchor:(float)anchor;

- (void)setDashRepeatAnchor:(float)anchor;

@end

/**
 * FMUniformGridConfiguration is a wrapper for struct unifim_gird_configuration that provides setter methods.
 *
 * dimensionIndex is an id of the dimension of an axis (if any) that this grid line intersects.
 * (decides dimIndex in FMGridLine initializer and therefore you should not modify it directly)
 */
@interface FMUniformGridConfiguration : NSObject

@property (readonly, nonatomic) id<MTLBuffer> _Nonnull buffer;
@property (readonly, nonatomic) uniform_grid_configuration * _Nonnull conf;

@property (assign  , nonatomic) float anchorValue;
@property (assign  , nonatomic) float interval;
@property (assign  , nonatomic) uint8_t dimensionIndex;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

- (void)setDepthValue:(float)depth;

@end


