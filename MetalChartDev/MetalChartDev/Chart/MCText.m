//
//  MCText.m
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/09/16.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "MCText.h"
#import <Metal/Metal.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreText/CoreText.h>
#import "DeviceResource.h"
#import "Engine.h"
#import "TextureQuads.h"
#import "TextureQuadBuffers.h"
#import "Lines.h"
#import "LineBuffers.h"

@interface MCTextBuffer()

@property (assign, nonatomic) void * data;
@property (assign, nonatomic) CTFontRef ctFont;
@property (assign, nonatomic) CGColorSpaceRef cgSpace;

@end

@implementation MCTextBuffer

- (instancetype)initWithBufferSize:(CGSize)size
{
    self = [super init];
    if(self) {
        _size = size;
        _cgSpace = CGColorSpaceCreateDeviceRGB();
        _data = malloc(4 * size.width * size.height);
    }
    return self;
}

- (void)setFont:(UIFont *)font
{
    if(_font != font) {
		if(_font){
			CFRelease(_ctFont);
			_ctFont = nil;
		}
        _font = font;
        if(font) {
            _ctFont = CTFontCreateWithName((CFStringRef)_font.fontName, _font.pointSize, NULL);
        }
    }
}

- (void)dealloc
{
    CGColorSpaceRelease(_cgSpace);
    free(_data);
    _cgSpace = NULL;
    _data = NULL;
}

- (void)drawString:(NSAttributedString *)string
         toTexture:(id<MTLTexture>)texture
       regionBlock:(MTLRegion (^ _Nonnull)(CGRect))block
{
    CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)string);
    
    const CGRect rect = CTLineGetBoundsWithOptions(line, kCTLineBoundsUseGlyphPathBounds);
    const CGSize size = rect.size;
    const MTLRegion region = block(rect);
    const float sx = 5;//(region.size.width) / size.width;
    const float sy = 5;//(region.size.height) / size.height;
    CGContextRef context = CGBitmapContextCreate(_data, region.size.width, region.size.height, 8, 4 * region.size.width, _cgSpace, kCGImageAlphaPremultipliedLast);
    CGContextScaleCTM(context, sx, sy);
	CGContextTranslateCTM(context, 0, 2);
    CGContextSetTextPosition(context, 0, 0);
    CTLineDraw(line, context);
    
    CGContextRelease(context);
    CFRelease(line);
    
    [texture replaceRegion:region mipmapLevel:0 withBytes:_data bytesPerRow:region.size.width * 4];
    
    memset(_data, 0, 4 * region.size.width * region.size.height);
}

@end


@interface MCText()

@property (assign, nonatomic) NSInteger idxMin;
@property (assign, nonatomic) NSInteger idxMax;
@property (assign, nonatomic) CGSize bufSize;
@property (assign, nonatomic) NSUInteger capacity;

@end

@implementation MCText

- (instancetype)initWithEngine:(Engine *)engine
             drawingBufferSize:(CGSize)bufSize
                bufferCapacity:(NSUInteger)capacity
                 labelDelegate:(id<MCAxisLabelDelegate> _Nonnull)delegate
{
	self = [super init];
	if(self) {
		_engine = engine;
		MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm width:bufSize.width height:bufSize.height * capacity mipmapped:NO];
		id<MTLTexture> texture = [engine.resource.device newTextureWithDescriptor:desc];
		_quad = [[TextureQuad alloc] initWithEngine:engine texture:texture];
		_buffer = [[MCTextBuffer alloc] initWithBufferSize:bufSize];
		_buffer.font = [UIFont boldSystemFontOfSize:14];
        _bufSize = bufSize;
        _capacity = capacity;
        _delegate = delegate;
        _idxMin = 1;
        _idxMax = -1;
	}
	return self;
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
			  axis:(MCAxis *)axis projection:(UniformProjection *)projection
{
    [self configure:axis];
    const NSInteger count = MAX(0, (_idxMax-_idxMin) + 1);
	[_quad encodeWith:encoder projection:projection count:count];
}

- (void)configure:(MCAxis *)axis
{
    MCDimensionalProjection *dimension = axis.dimension;
    const CGFloat min = dimension.min;
    const CGFloat max = dimension.max;
    UniformAxisConfiguration *conf = axis.axis.attributes;
    const CGFloat anchor = conf.tickAnchorValue;
    const CGFloat interval = conf.majorTickInterval;
    const NSInteger newMin = ceil((min-anchor)/interval);
    const NSInteger newMax = floor((max-anchor)/interval);
    
    const NSInteger oldMin = _idxMin;
    const NSInteger oldMax = _idxMax;
    const CGSize bufSize = _bufSize;
    const NSInteger capacity = _capacity;
    for(NSInteger idx = newMin; idx <= newMax; ++idx) {
        if(!(oldMin <= idx && idx <= oldMax)) {
            const CGFloat value = anchor + (idx * interval);
            NSAttributedString *str = [_delegate attributedStringForValue:value dimension:dimension];
            [_buffer drawString:str toTexture:_quad.texture regionBlock:^(const CGRect rect) {
                const CGFloat r = (rect.origin.x+rect.size.width) / (rect.origin.y+rect.size.height);
                const CGFloat w = ceil(MIN(bufSize.width, r * bufSize.height));
                const CGFloat h = ceil(MIN(bufSize.height, bufSize.width / r));
                const CGFloat x = 0.5 * (bufSize.width - w);
                NSInteger wrapped_idx = (idx % capacity);
                if(wrapped_idx < 0) wrapped_idx += capacity;
                const CGFloat y = 0.5 * (bufSize.height - h) + (wrapped_idx * bufSize.height);
                return MTLRegionMake2D(x, y, w, h);
            }];
        }
    }
    
    [conf checkIfMajorTickValueModified:^BOOL(UniformAxisConfiguration *conf) {
        UniformRegion *texRegion = _quad.texRegion;
        const CGFloat normHeight = 1 / (CGFloat)self.capacity;
        [texRegion setIterationVector:CGPointMake(0, normHeight)];
        [texRegion setSize:CGSizeMake(1, normHeight)];
        UniformRegion *dataRegion = _quad.dataRegion;
        const CGFloat aVal = conf.axisAnchorValue;
        const CGFloat tVal = conf.tickAnchorValue;
        [dataRegion setIterationVector:(conf.dimensionIndex == 0) ? CGPointMake(interval, 0) : CGPointMake(0, interval)];
        [dataRegion setBasePosition:(conf.dimensionIndex == 0) ? CGPointMake(tVal, aVal) : CGPointMake(aVal, tVal)];

        return YES;
    }];
    [_quad.texRegion setIterationOffset:newMin];
    [_quad.dataRegion setIterationOffset:newMin];
	_idxMax = newMax;
	_idxMin = newMin;
}

@end

@interface MCAxisLabelBlockDelegate()

@property (copy, nonatomic) MCAxisLabelDelegateBlock block;

@end

@implementation MCAxisLabelBlockDelegate

- (instancetype)initWithBlock:(MCAxisLabelDelegateBlock)block
{
    self = [super init];
    if(self) {
        self.block = block;
    }
    return self;
}

- (NSAttributedString *)attributedStringForValue:(CGFloat)value
                                       dimension:(MCDimensionalProjection *)dimension
{
    return _block(value, dimension);
}

@end


















