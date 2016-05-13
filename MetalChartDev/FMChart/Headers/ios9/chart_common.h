//
//  chart_common.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/07.
//  Copyright © 2015年 freaks. All rights reserved.
//

#ifndef chart_common_h
#define chart_common_h

#ifdef __cplusplus

#endif

#import <MetalKit/MetalKit.h>
#import "FMMetalView.h"
#import "Prototypes.h"

// 当初はMTKViewを使って開発されていたが、event-drivenモードにて挙動が好ましくない部分があった
// (drawコールがDisplayのリフレッシュに合わせた回数ではなく、何回でも呼ばれてしまい、排他制御で即時リターンする時にsetNeedsDisplayすると
//  スリープなしで戻ってきてしまう)
// 今の所FMChartSupport(iOS8から)と動作上の差異がなくなっているが、実際にはStoryboardに記述するクラス名を変更しないと実際のビューは
// 変わらない事に注意（インタフェース互換ではあるのでMTKViewを指定してもクラッシュはしないが、上述の挙動をする）
// 当分はios8/の方を参照し、このヘッダは使われない.

@compatibility_alias MetalView MTKView;

@protocol MetalViewDelegate<MTKViewDelegate>
@end

#endif /* chart_common_h */
