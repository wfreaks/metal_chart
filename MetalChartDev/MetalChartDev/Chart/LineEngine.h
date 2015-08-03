//
//  LineEngine.h
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/08/03.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DeviceResource.h"

@interface LineEngine : NSObject

@property (readonly, nonatomic) DeviceResource *resource;
@property (readonly, nonatomic) NSUInteger capacity;

- (id)initWithResource:(DeviceResource *)resource
		bufferCapacity:(NSUInteger)capacity;

@end
