# FMChart Documentation

FMChart is a charting framework that utilizes Metal API on A7+ iOS devices running iOS 8 or later. 

## Main Features

+ thin & light
+ flexible & customizable
+ fast
+ low CPU loads
+ explicit

## Concepts & Models

In FMChart, a chart consists of : 

+ Data space 
+ Data series (in above space)
+ Projections (Data Space -> View)
+ Data Renderers (series+projection -> lines/points)
+ Attachment (Axis, label, plot area, etc)
+ Chart (container for above elements, view delegate)

You need to allocate them, configure their properties and
 relationships in order to fully manipulate a chart.  
(You can use the utilities to omit conventional lines, though)

## Sample Codes

See [HealthKit sample](MetalChartDev/ViewControllers/HealthKitViewController.m).
The view controller queries all systolic/diastolic
blood pressures, weights and daily step counts from HealthKit, 
and then show them simultaneously.

## Workflow

1. Put a chart view (FMMetalView) on your storyboards / xibs.
1. Create chart (and configurator if needed, configure view/delegate otherwise)
1. Create dimensions, range filters, projection(range) updaters
1. Create space by combining above dimensions
1. Create data containers (series), insert data points if ready
1. Create data renderers(FMRenderable) that hold the containers
1. Create attachments (axis, labels, gridlines, plot area) 
1. Manage attributes(FMUniformXXXAttributes) and configurations
1. Add renderers/attachments to chart (if not using configurator)
1. (Re)Load data if necessary

Note that a [FMChartConfigurator](FMChart/Chart/FMChartConfigurator.h) instance can perform almost all object allocations and initial settings.

#### Chart & Configurator

See 
+ [FMMetalChart](FMChart/Chart/FMMetalChart.h)
+ [FMChartConfigurator](FMChart/Chart/FMChartConfigurator.h)

If you are not using FMChartConfigurator, you should follow : 
+ Create FMSurfaceConfiguration instance FMEngine instance
+ Configure using [FMChartConfigurator configureMetalChart: view: preferredFps].
+ Set engine.device to view.device
+ Set chart as view.delegate
+ Create FMAnimator and FMGestureDispatcher, set relations

#### Creating Dimensions & Spaces

See  
+ [FMProjection](FMChart/Chart/FMMetalChart.h)
+ [FMDimensionalProjection](FMChart/Chart/FMProjections)
+ [FMProjectionCartesian2D](FMChart/Chart/FMProjections)
+ [FMProjectionUpdater](FMChart/Chart/FMProjectionUpdater.h)
+ [Range Filters](FMChart/Chart/FMRangeFilters.h)

#### Adding Axes

See
+ [FMAxis](FMChart/Chart/FMAxis.h)
+ [FMAxisPrimitive](FMChart/Engine/Line/Lines.h)
+ [FMUniformAxisAttributes](FMChart/Engine/Line/LineBuffers.h)

Prefer using FMExclusiveAxis to FMSharedAxis when possible. You can share a range through dimension and updater even if you have multiple charts, space, axes and axis labels instances.

#### Adding Labels to Axes

See
+ [FMAxisLabel](FMChart/Chart/FMAxisLabel.h)

FMAxisLabel requires Core Text and Core Graphics.  
You can perform additional action to context before each text line rendering, and modify ranges of valid render cache (e.g. invalidate 3 labels from left side)

#### Adding Grid Lines

See
+ [FMGridLine](FMChart/Chart/FMRenderables.h)
+ [FMUniformGridAttributes](FMChart/Engine/Line/LineBuffers.h)

A grid line instance can be used without an axis (in this case you should manage configurations manually).


## License 

This software is released under the [MIT License](LICENSE.txt).
