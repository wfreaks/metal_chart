//
//  MetalChart.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/09.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "chart_common.h"
#import "Engine_common.h"

/**
 * This header file defines all components that are not replacable.
 * The interest of those components is 'projection' (mapping from data space to view space).
 * While Axis, ticks, managing visible ranges and user interactions are provided by default implementations,
 * they are all replaceable by custom implementations (I dont think it's easy though).
 * you can define your own renderables (visualizable data series) by writing shaders and wrapper class.
 */

/**
 * Determine a pixel format that is suitable for the device and the os version.
 */

MTLPixelFormat determineDepthPixelFormat();

/**
 * FMDepthClient protocol defines methods that all attachements and renderables utilizing depth test must implement.
 * clients must record parameter min and return value r and use those values in order to get correct drawing results.
 * r should be a positive value of zero if you do not require special behavior described below.
 * (available depth range to the client will be [min, min+r). )
 *
 * returning negative value requests a chart to allocate range below depth clear value.
 * (returning -r means chart.clearValue will be increased by r if r > 0.)
 *
 * It is not considered that multiple clients returns negative values for now.
 * (there might be future changes in protocol)
 */

@protocol FMDepthClient <NSObject>

- (CGFloat)requestDepthRangeFrom:(CGFloat)min
						 objects:(NSArray * _Nonnull)objects;

@end


/**
 * FMRenderable represents series of visualizable data.
 * encodeWith:chart: will be called after updating projections, executing hooks, and rendering pre-series attachements (filling plot area and etc),
 * then post-series attachments will be drawn.
 * this protocol does not tell anything about projections, but a usual renderable object requires a projection.
 * 
 * to draw a renderable object, it must be added to chart using addRenderable: method.
 * 
 * An FMRenderable object SHOULD NOT have dependencies to other data series or attachments since it's series of visualizable data.
 * If it has any dependency, then make it an FMDependentAttachment object.
 */

@protocol FMRenderable<NSObject>

- (void)encodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
			 chart:(MetalChart * _Nonnull)chart
;

@end


/**
 * FMAttachment represents an additional element that is drawn on chart, including axis and labels.
 * To allow attachments to access more contextual info, encodeWith:chart:view passes an extra argument 'view',
 * but its roll is very similar to that of FMRenderable.
 *
 * Attachments can have dependencies regardless of their drawing(z-dimensinal) order.
 * See FMDependentAttachment protocol for details.
 */

@protocol FMAttachment <NSObject>

- (void)encodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
			 chart:(MetalChart * _Nonnull)chart
			  view:(MetalView * _Nonnull)view
;

@end


/**
 * FMDependentAttachment represents an attachement that has preparation procedure before issueing draw calls (such as an axis to decide its position),
 * or an attachment that has an other dependent attachment (such as an label depending on an axis)
 *
 * Any attachments that has preparation stage (i.e. updating properties or gpu buffers) must implement this element, even if if does not have any dependency,
 * since it has no way to know whether there is any attachment that depends on it or not.
 * (the protocol name is not really a right one i guess...)
 *
 * prepare:view: will be called in order regarding the dependency tree (not drawing order), and the tree get calculated
 * every time FMDependentAttachment is added/removed into/from a chart.
 * if you modify dependencies by operation other than that, then you are responsible for calling [chart requestResolveAttachmentDependencies].
 *
 * And one more thing, you MUST NOT make a cyclic dependency (though it won't throw any exception nor cause stack overflow).
 */

@protocol FMDependentAttachment <FMAttachment>

- (void)prepare:(MetalChart * _Nonnull)chart
		   view:(MetalView * _Nonnull)view
;

@optional
- (NSArray<id<FMDependentAttachment>> * _Nullable)dependencies
;

@end


/**
 * FMCommandBufferHook provides a customizing point for a chart.
 * Implementation objects can use MTLCommandBuffer to execute custom processings (i.e. perform gpu calculation).
 *
 * Default animation class implement this protocol.
 * if you want to use multiple hooks on a single chart, then you can make hook array class to delegate calls.
 */

@protocol FMCommandBufferHook <NSObject>

- (void)chart:(MetalChart * _Nonnull)chart willStartEncodingToBuffer:(id<MTLCommandBuffer> _Nonnull)buffer;
- (void)chart:(MetalChart * _Nonnull)chart willCommitBuffer:(id<MTLCommandBuffer> _Nonnull)buffer;

@end


/**
 * FMProjection protocol provides information about view dimensions that mapping objects (having GPU buffers)
 * need to know, and notify that it should update gpu buffers it have.
 */
@protocol FMProjection <NSObject>

- (void)configure:(MetalView * _Nonnull)view padding:(FMRectPadding)padding;

@end

/**
 * MetalChart class is a MetalViewDelegate object that manages elements of a chart.
 * It can be shared by multiple MetalView instance, but may cause problems (not considered on the design phase).
 * I can't think of any meaningfull usecase of sharing a chart.
 *
 * Adding attachments/series in an order of A->B results in B drawn over A.
 * Adding an attachment/series that is already added does nothing, and is same for removing an item which is not added yet.
 * 
 * Since FMRenderable and FMAttachment do not require implementations to provide projection it uses, 
 * you must explicitly register/unregister FMProjection objects in order to draw renderables/attachment that needs projections to be updated/flushed.
 */

@interface MetalChart : NSObject<MetalViewDelegate>

@property (weak   , nonatomic) id<FMCommandBufferHook> _Nullable bufferHook;

/**
 * padding doesn't do anything by itself, but default implementations (such as FMProjectionCartesian2D) use it to configure their appearance and behavior.
 */
@property (assign , nonatomic) FMRectPadding padding;

/**
 * You don't have to check this value.
 */
@property (readonly, nonatomic) CGFloat clearDepth;

/**
 * address string for this instance to be used as a dictionary key.
 */
@property (readonly, nonatomic) NSString * _Nonnull key;

- (instancetype _Nonnull)init NS_DESIGNATED_INITIALIZER;

- (void)addRenderable:(id<FMRenderable> _Nonnull)renderable;
- (void)addRenderableArray:(NSArray<id<FMRenderable>> *_Nonnull)renderables;
- (void)removeRenderable:(id<FMRenderable> _Nonnull)renderable;

- (void)addProjection:(id<FMProjection> _Nonnull)projection;
- (void)addProjections:(NSArray<id<FMProjection>> *_Nonnull)projections;
- (void)removeProjection:(id<FMProjection> _Nonnull)projection;

- (void)addPreRenderable:(id<FMAttachment> _Nonnull)object;
- (void)insertPreRenderable:(id<FMAttachment> _Nonnull)object atIndex:(NSUInteger)index;
- (void)addPreRenderables:(NSArray<id<FMAttachment>> * _Nonnull)array;
- (void)removePreRenderable:(id<FMAttachment> _Nonnull)object;

- (void)addPostRenderable:(id<FMAttachment> _Nonnull)object;
- (void)insertPostRenderable:(id<FMAttachment> _Nonnull)object atIndex:(NSUInteger)index;
- (void)addPostRenderables:(NSArray<id<FMAttachment>> * _Nonnull)array;
- (void)removePostRenderable:(id<FMAttachment> _Nonnull)object;

- (void)removeAll;

- (void)requestResolveAttachmentDependencies;

- (NSArray<id<FMRenderable>> * _Nonnull)renderables;

- (NSSet<id<FMProjection>> * _Nonnull)projectionSet;

@end



