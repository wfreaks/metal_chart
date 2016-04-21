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

#define FM_INLINE static inline

typedef struct RectPadding {
	CGFloat left;
	CGFloat top;
	CGFloat right;
	CGFloat bottom;
} RectPadding;

FM_INLINE bool __RectPaddingEqualsTo(RectPadding a, RectPadding b) {
	return a.left == b.left && a.top == b.top && a.right == b.right && a.bottom == b.bottom;
}
#define RectPaddingEqualsTo __RectPaddingEqualsTo

FM_INLINE RectPadding __RectPaddingMake(CGFloat left, CGFloat right, CGFloat top, CGFloat bottom) {
	RectPadding padding = {left, right, top, bottom};
	return padding;
}
#define RectPaddingMake __RectPaddingMake


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
