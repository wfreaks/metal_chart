//
//  MCRestrictions.h
//  MetalChartDev
//
//  Created by Mori Keisuke on 2015/08/10.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCProjectionUpdater.h"

typedef void (^RestrictionBlock)(MCProjectionUpdater *_Nonnull updater, CGFloat * _Nonnull min, CGFloat * _Nonnull max);

@class MCProjectionUpdater;

@protocol MCRestriction<NSObject>

- (void)updater:(MCProjectionUpdater * _Nonnull)updater
	   minValue:(CGFloat * _Nonnull)min
	   maxValue:(CGFloat * _Nonnull)max
;

@end


// 範囲長を固定する. Anchorの値は-1でmin, +1でmaxを指し、その点を固定した状態で拡大縮小する.
// つまりanchor=-1の場合、minを変更せずmaxのみを動かし、anchor=1ならば中央値を固定してmin,maxを動かす.
@interface MCLengthRestriction : NSObject<MCRestriction>

@property (readonly, nonatomic) CGFloat length;
@property (readonly, nonatomic) CGFloat anchor;

- (_Null_unspecified instancetype)initWithLength:(CGFloat)length
										  anchor:(CGFloat)anchor;

@end


// updaterのsource{Min,Max}Valueがnilの時、あるいは代替値に達しなかった場合には代替値で、
// それ以外の場合にはsourceの値でmin/maxを更新する. このクラスはmin/maxの現在地を「完全に」無視する.
// sourceの値が代替値に達していなくてもsourceの値を使いたい場合はexpand{Min,Max}をNOにする.
// 優先度的に低い方に来るのが普通の使い方だろう.
@interface MCAlternativeSourceRestriction : NSObject<MCRestriction>

@property (readonly, nonatomic) CGFloat min;
@property (readonly, nonatomic) CGFloat max;
@property (readonly, nonatomic) BOOL    expandMin;
@property (readonly, nonatomic) BOOL    expandMax;

- (_Null_unspecified instancetype)initWithMinValue:(CGFloat)min
										  maxValue:(CGFloat)max
										 expandMin:(BOOL)expandMin
										 expandMax:(BOOL)expandMax
;

@end

// sourceまたは現在のmin/maxにpaddingを加える.
// allowShrinkはsourceから計算した新しい値が範囲を狭める場合にその値を使うか否か,
// applyToCurrentMinMaxはpaddingを現在値に加えるかどうか. 例えばAlternativeSourceの次に使う場合は
// 現在のmin/maxが補正されてsourceMin/Maxのように働くため.
@interface MCSourcePaddingRestriction : NSObject<MCRestriction>

@property (readonly, nonatomic) CGFloat paddingLow;
@property (readonly, nonatomic) CGFloat paddingHigh;
@property (readonly, nonatomic) BOOL    allowShrink;
@property (readonly, nonatomic) BOOL    applyToCurrentMinMax;

- (_Null_unspecified instancetype)initWithPaddingLow:(CGFloat)low
												high:(CGFloat)high
									  applyToCurrent:(BOOL)apply
											  shrink:(BOOL)shrink;

@end

@interface MCBlockRestriction : NSObject<MCRestriction>

- (_Null_unspecified instancetype)initWithBlock:(RestrictionBlock _Nonnull)block;

@end
