//
//  Prototypes.h
//  MetalChartDev
//
//  Created by Keisuke Mori on 2016/04/15.
//  Copyright © 2016年 freaks. All rights reserved.
//

#ifndef Prototypes_h
#define Prototypes_h

@protocol FMAxis;
@protocol FMRangeFilter;
@protocol FMSeries;

@class FMAnimator;
@class FMArrayBuffer;
@class FMAxisPrimitive;
@class FMBarPrimitive;
@class FMContinuosArcPrimitive;
@class FMDeviceResource;
@class FMDimensionalProjection;
@class FMEngine;
@class FMGestureDispatcher;
@class FMGridLinePrimitive;
@class FMIndexedFloatBuffer;
@class FMLinePrimitive;
@class FMOrderedAttributedBarPrimitive;
@class FMOrderedAttributedPointPrimitive;
@class FMOrderedAttributedPolyLinePrimitive;
@class FMOrderedAttributedSeries;
@class FMOrderedBarPrimitive;
@class FMOrderedPointPrimitive;
@class FMOrderedPolyLinePrimitive;
@class FMOrderedSeries;
@class FMDefaultFilter;
@class FMPanGestureRecognizer;
@class FMPieDoughnutSeries;
@class FMPlotArea;
@class FMPointPrimitive;
@class FMPlotRectPrimitive;
@class FMProjectionCartesian2D;
@class FMProjectionPolar;
@class FMProjectionUpdater;
@class FMSurfaceConfiguration;
@class FMUniformArcAttributesArray;
@class FMUniformArcConfiguration;
@class FMUniformAxisAttributes;
@class FMUniformAxisConfiguration;
@class FMUniformBarAttributes;
@class FMUniformBarConfiguration;
@class FMUniformGridAttributes;
@class FMUniformLineAttributes;
@class FMUniformLineAttributesArray;
@class FMUniformLineConf;
@class FMUniformPlotRectAttributes;
@class FMUniformPointAttributes;
@class FMUniformPointAttributesArray;
@class FMUniformProjectionCartesian2D;
@class FMUniformProjectionPolar;
@class FMUniformBarAttributesArray;
@class FMUniformRegion;
@class FMUniformSeriesInfo;
@class TextureQuad;
@class MetalChart;


typedef NS_ENUM(NSInteger, FMDimOrientation) {
	FMDimOrientationHorizontal = 0,
	FMDimOrientationVertical = 1,
};

#endif /* Prototypes_h */
