//
//  FMProperty.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2016/03/21.
//  Copyright © 2016年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 * 煩雑なAppearanceに関する設定をJSONなどで記述するための、ユーティリティクラス.
 * 
 */

@interface FMProperty : NSObject

+ (void)applyDictionary:(NSDictionary *)dictionary
			   toObject:(id)object
;

@end
