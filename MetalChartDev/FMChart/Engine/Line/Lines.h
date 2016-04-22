//
//  PolyLines.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/06.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import "Protocols.h"
#import "Prototypes.h"

@interface FMLinePrimitive : NSObject<FMPrimitive>

@property (nonatomic, readonly) FMUniformLineConf * _Nonnull conf;
@property (readonly, nonatomic) FMEngine * _Nonnull engine;

- (id<FMSeries> _Nullable)series;

@end



@interface FMPolyLinePrimitive : FMLinePrimitive

@end



@interface FMOrderedPolyLinePrimitive : FMPolyLinePrimitive

@property (nonatomic) FMUniformLineAttributes * _Nonnull attributes;
@property (nonatomic) FMUniformPointAttributes * _Nullable pointAttributes;
@property (nonatomic) FMOrderedSeries * _Nullable series;

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
								   orderedSeries:(FMOrderedSeries * _Nullable)series
									  attributes:(FMUniformLineAttributes * _Nullable)attributes
;

@end


// attributedPointを追加すると、データ点にindexがふくまれてしまうのでかなり使い勝手が悪くなる.
// なら手動でattributedPointを追加してもらった方が、ずっとよいと思われる. (そもそもlineにpointを追加できる必要性ってあんまりない)
@interface FMOrderedAttributedPolylinePrimitive : FMPolyLinePrimitive

@property (nonatomic) FMUniformLineAttributesArray * _Nonnull attributesArray;
@property (nonatomic) FMOrderedAttributedSeries * _Nullable series;

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
						  orderedSeries:(FMOrderedAttributedSeries * _Nullable)series
                     attributesCapacity:(NSUInteger)capacity
;

@end



@interface FMAxisPrimitive : NSObject

@property (readonly, nonatomic) FMUniformAxisConfiguration * _Nonnull configuration;
@property (readonly, nonatomic) FMUniformAxisAttributes * _Nonnull axisAttributes;
@property (readonly, nonatomic) FMUniformAxisAttributes * _Nonnull majorTickAttributes;
@property (readonly, nonatomic) FMUniformAxisAttributes * _Nonnull minorTickAttributes;

@property (readonly, nonatomic) FMEngine * _Nonnull engine;

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
;

- (void)encodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
		projection:(FMUniformProjectionCartesian2D * _Nonnull)projection
;

@end




@interface FMGridLinePrimitive : NSObject

@property (readonly, nonatomic) FMUniformGridAttributes * _Nonnull attributes;

@property (readonly, nonatomic) FMEngine * _Nonnull engine;

- (instancetype _Nonnull)initWithEngine:(FMEngine * _Nonnull)engine
NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;

- (void)encodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
		projection:(FMUniformProjectionCartesian2D * _Nonnull)projection
		  maxCount:(NSUInteger)maxCount
;


@end



