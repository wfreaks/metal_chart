//
//  Protocols.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/28.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MTLRenderCommandEncoder;

@class UniformProjection;

@protocol Primitive <NSObject>

- (void)encodeWith:(id<MTLRenderCommandEncoder> _Nonnull)encoder
		projection:(UniformProjection * _Nonnull)projection
;

@end

