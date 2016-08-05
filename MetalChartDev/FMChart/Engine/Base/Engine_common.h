//
//  Engine_common.h
//  FMChart
//
//  Created by Keisuke Mori on 2015/08/25.
//  Copyright © 2015年 freaks. All rights reserved.
//

#ifndef Engine_common_h
#define Engine_common_h

#import "base_shared.h"
#import <CoreGraphics/CGGeometry.h>

#define FM_INLINE static inline

typedef struct FMRectPadding {
	CGFloat left;
	CGFloat top;
	CGFloat right;
	CGFloat bottom;
} FMRectPadding;

FM_INLINE bool __FMRectPaddingEqualsTo(FMRectPadding a, FMRectPadding b) {
	return a.left == b.left && a.top == b.top && a.right == b.right && a.bottom == b.bottom;
}
#define FMRectPaddingEqualsTo __FMRectPaddingEqualsTo

FM_INLINE FMRectPadding __FMRectPaddingMake(CGFloat left, CGFloat right, CGFloat top, CGFloat bottom) {
	FMRectPadding padding = {left, right, top, bottom};
	return padding;
}
#define FMRectPaddingMake __FMRectPaddingMake


/**
 * position of each corner will be differ depending on context (the direction 'top' and 'right' may differ from that of the device).
 */

typedef struct {
	float lt;
	float rt;
	float lb;
	float rb;
} FMRectCornerRadius;

FM_INLINE bool __FMRectCornerRadiusEqualsTo(FMRectCornerRadius a, FMRectCornerRadius b) {
	return a.lt == b.lt && a.rt == b.rt && a.lb == b.lb && a.rb == b.rb;
}
#define FMRectCornerRadiusEqualsTo __FMRectCornerRadiusEqualsTo

FM_INLINE FMRectCornerRadius __FMRectCornerRadiusMake(CGFloat lt, CGFloat rt, CGFloat lb, CGFloat rb) {
	FMRectCornerRadius corner = {(float)lt, (float)rt, (float)lb, (float)rb};
	return  corner;
}
#define FMRectCornerRadiusMake __FMRectCornerRadiusMake


#ifdef __cplusplus

class vertex_container {
	
	vertex_float2 *_buffer;
	const std::size_t _capacity;
	
	public :
	
	vertex_container(void *ptr, std::size_t capacity) :
	_buffer(static_cast<vertex_float2 *>(ptr)),
	_capacity(capacity)
	{}
	
	std::size_t capacity() const { return _capacity; }
	vertex_float2& operator[](std::size_t index) { return _buffer[index]; }
	const vertex_float2& operator[](std::size_t index) const { return _buffer[index]; }
	
};

#endif


#endif /* Engine_common_h */
