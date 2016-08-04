//
//  RectBuffers.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/26.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import "Rect_common.h"
#import "Buffers.h"
#import "Engine.h"


@interface NSValue (FMRectCornerRadius)

+ (instancetype _Nonnull)valueWithCornerRadius:(FMRectCornerRadius)radius;
- (FMRectCornerRadius)FMRectCornerRadiusValue;

@end

/**
 * FMUniformPlotRectAttributes is a wrapper class for struct uniform_plot_rect that provides setter methods.
 * The direction 'top' is defined by user interface (i.e. that of the view coordinate system).
 * color vectors are in RGBA format.
 * You better not to call setDepthValue directly (it is for FMPlotArea) unless you're implementing custom primitives.
 */

@interface FMUniformPlotRectAttributes : NSObject

@property (readonly, nonatomic) id<MTLBuffer> _Nonnull buffer;
@property (readonly, nonatomic) uniform_plot_rect * _Nonnull rect;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource;

- (void)setColor:(UIColor *_Nonnull)color;
- (void)setColorVec:(vector_float4)color;
- (void)setColorVecRef:(const vector_float4 *_Nonnull)color;
- (void)setColorRed:(float)r green:(float)g blue:(float)b alpha:(float)a;

- (void)setCornerRadius:(float)lt rt:(float)rt lb:(float)lb rb:(float)rb;
- (void)setCornerRadius:(FMRectCornerRadius)radius;
- (void)setAllCornerRadius:(float)radius;
- (void)setDepthValue:(float)value;

@end


/**
 * FMUniformBarConfiguration is a wrapper class for struct uniform_bar_conf that provides setter methods.
 *
 * barDirection property determines which direction a bar with positive value will extend,
 * and more importantly, it decides which is 'top'.
 *
 * anchorPoint decides the origin (and where bars extend from)
 *
 * The point is, the data point is given in the form of 2-component value :
 * so 'the goal' of the bar extension is decided solely by the data point, and
 * 'the origin/root' of the bar is decided by anchorPoint and direction.
 *
 * Well in most cases, what you need to do is so simple :
 * set barDirection = (0,1) for bar series and barDirection = (1, 0) for column series.
 * (keep anchorPoint to (0, 0).)
 */

@interface FMUniformBarConfiguration : NSObject

@property (readonly, nonatomic) id<MTLBuffer> _Nonnull buffer;
@property (readonly, nonatomic) uniform_bar_conf * _Nonnull conf;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource;

- (void)setDepthValue:(float)value;
- (void)setAnchorPoint:(CGPoint)point;
- (void)setBarDirection:(CGPoint)dir;

@end

/**
 * FMUniformBarAttributes is a wrapper class for struct uniform_bar_attr that provides setter methods.
 * Interpretations of inner/outer radius and colors are equivalent to those of FMUniformPlotRect.
 *
 * see FMUniformBarConfiguration for general interpretation of the 'top'.
 * if the given value is negative, then 'top' will be reverted (direction which the bar extends),
 * but the 'left' and the 'right' will not.
 * (barDirection=(0,1), value=(1, -1), then the bar will extends downward, so the 'top' means downward, but 'left' remains left(negative x),
 *  and the 'rigtht' remains right (positive x)).
 *
 */

@interface FMUniformBarAttributes : FMAttributesBuffer

@property (readonly, nonatomic) uniform_bar_attr * _Nonnull attr;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
                                     size:(NSUInteger)size
UNAVAILABLE_ATTRIBUTE;

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource;

- (void)setColor:(UIColor *_Nonnull)color;
- (void)setColorVec:(vector_float4)color;
- (void)setColorVecRef:(const vector_float4 *_Nonnull)color;
- (void)setColorRed:(float)r green:(float)g blue:(float)b alpha:(float)a;

/**
 * For interpretations of each corner's position, see class summary.
 * all radiuses are in logical pixels.
 */
- (void)setCornerRadius:(float)lt rt:(float)rt lb:(float)lb rb:(float)rb;

/**
 * For interpretations of each corner's position, see class summary.
 * all radiuses are in logical pixels.
 */
- (void)setCornerRadius:(FMRectCornerRadius)radius;

/**
 * sets uniformal radius in logical pixels to all corners.
 */
- (void)setAllCornerRadius:(float)radius;

/**
 * sets bar width in logical pixels.
 */
- (void)setBarWidth:(float)width;

@end

/**
 * See FMAttributesArray, FMArrayBuffer and FMUniformBarAttributes for details.
 */

@interface FMUniformBarAttributesArray : FMAttributesArray<FMUniformBarAttributes*>

- (instancetype _Nonnull)initWithResource:(FMDeviceResource * _Nonnull)resource
								 capacity:(NSUInteger)capacity
;

@end



