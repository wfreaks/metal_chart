//
//  FMAxisLabel.m
//  MetalChartDev
//
//  Created by Keisuke Mori on 2015/09/16.
//  Copyright © 2015年 freaks. All rights reserved.
//

#import "FMAxisLabel.h"
#import <Metal/Metal.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreText/CoreText.h>
#import "DeviceResource.h"
#import "Engine.h"
#import "TextureQuads.h"
#import "TextureQuadBuffers.h"
#import "Lines.h"
#import "LineBuffers.h"

@interface FMTextRenderer()

@property (assign, nonatomic) void * data;
@property (assign, nonatomic) CTFontRef ctFont;
@property (assign, nonatomic) CGColorSpaceRef cgSpace;

@end

@implementation FMTextRenderer

- (instancetype)initWithBufferSize:(CGSize)size
{
    self = [super init];
    if(self) {
        _bufferSize = size;
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
            _ctFont = CTFontCreateWithName((CFStringRef)font.fontName, font.pointSize, NULL);
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

- (void)drawString:(NSMutableAttributedString *)string
         toTexture:(id<MTLTexture>)texture
         confBlock:(FMTextDrawConfBlock _Nonnull)block
{
    CTFontRef font = _ctFont;
    if(font) {
        [string addAttribute:(NSString *)kCTFontAttributeName
                       value:(__bridge id)font
                       range:NSMakeRange(0, string.length)];
    }
    CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)string);
    
    const CGRect glyphRect = CTLineGetBoundsWithOptions(line, kCTLineBoundsUseGlyphPathBounds);
    const CGSize bufSize = _bufferSize;
    CGRect drawRect;
    const MTLRegion region = block(glyphRect.size, bufSize, &drawRect);
    const float sx = (drawRect.size.width) / glyphRect.size.width;
    const float sy = (drawRect.size.height) / glyphRect.size.height;
    CGContextRef context = CGBitmapContextCreate(_data, bufSize.width, bufSize.height, 8, 4 * bufSize.width, _cgSpace, kCGImageAlphaPremultipliedLast);
    CGContextClearRect(context, CGRectMake(0, 0, bufSize.width, bufSize.height));
    CGContextTranslateCTM(context, drawRect.origin.x , drawRect.origin.y);
    CGContextScaleCTM(context, sx, sy);
    CGContextTranslateCTM(context, -glyphRect.origin.x, -glyphRect.origin.y);
    CGContextSetTextPosition(context, 0, 0);
    CTLineDraw(line, context);
    
    CGContextRelease(context);
    CFRelease(line);
    
    [texture replaceRegion:region mipmapLevel:0 withBytes:_data bytesPerRow:bufSize.width * 4];
}

@end


@interface FMAxisLabel()

@property (readonly, nonatomic) FMTextRenderer * _Nonnull buffer;
@property (assign, nonatomic) NSInteger idxMin;
@property (assign, nonatomic) NSInteger idxMax;
@property (assign, nonatomic) NSUInteger capacity;

@end

@implementation FMAxisLabel

- (instancetype)initWithEngine:(Engine *)engine
                     frameSize:(CGSize)frameSize
                bufferCapacity:(NSUInteger)capacity
                 labelDelegate:(id<FMAxisLabelDelegate> _Nonnull)delegate
{
	self = [super init];
	if(self) {
        const CGFloat scale = [UIScreen mainScreen].scale;
        const CGSize bufSize = CGSizeMake(scale * frameSize.width, scale * frameSize.height);
		MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm width:bufSize.width height:bufSize.height * capacity mipmapped:NO];
		id<MTLTexture> texture = [engine.resource.device newTextureWithDescriptor:desc];
		_quad = [[TextureQuad alloc] initWithEngine:engine texture:texture];
		_buffer = [[FMTextRenderer alloc] initWithBufferSize:bufSize];
        _capacity = capacity;
        _delegate = delegate;
        _idxMin = 1;
        _idxMax = -1;
        _textAlignment = CGPointMake(0.5, 0.5);
        
        [_quad.dataRegion setSize:frameSize];
        [_quad.dataRegion setAnchorPoint:CGPointMake(0.5, 0.5)];
	}
	return self;
}

- (void)setFont:(UIFont *)font
{
    _buffer.font = font;
}

- (void)setFrameOffset:(CGPoint)offset
{
    [_quad.dataRegion setPositionOffset:offset];
}

- (void)setFrameAnchorPoint:(CGPoint)point
{
    [_quad.dataRegion setAnchorPoint:point];
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
			  axis:(FMAxis *)axis projection:(UniformProjection *)projection
{
    [self configure:axis];
    const NSInteger count = MAX(0, (_idxMax-_idxMin) + 1);
	[_quad encodeWith:encoder projection:projection count:count];
}

- (void)configure:(FMAxis *)axis
{
    FMDimensionalProjection *dimension = axis.dimension;
    const CGFloat min = dimension.min;
    const CGFloat max = dimension.max;
    UniformAxisConfiguration *conf = axis.axis.configuration;
    const CGFloat anchor = conf.tickAnchorValue;
    const CGFloat interval = conf.majorTickInterval;
    const NSInteger newMin = ceil((min-anchor)/interval);
    const NSInteger newMax = floor((max-anchor)/interval);
    
    UniformRegion *texRegion = _quad.texRegion;
    UniformRegion *dataRegion = _quad.dataRegion;
    const CGFloat aVal = conf.axisAnchorValue;
    const CGFloat tVal = conf.tickAnchorValue;
    [conf checkIfMajorTickValueModified:^BOOL(UniformAxisConfiguration *conf) {
        const CGFloat normHeight = 1 / (CGFloat)self.capacity;
        [texRegion setIterationVector:CGPointMake(0, normHeight)];
        [texRegion setSize:CGSizeMake(1, normHeight)];
        [dataRegion setIterationVector:(conf.dimensionIndex == 0) ? CGPointMake(interval, 0) : CGPointMake(0, interval)];
        _idxMax = -1;
        _idxMin = 0;
        
        return YES;
    }];
    [texRegion setIterationOffset:newMin];
    [dataRegion setIterationOffset:newMin];
    [dataRegion setBasePosition:(conf.dimensionIndex == 0) ? CGPointMake(tVal, aVal) : CGPointMake(aVal, tVal)];
    
    const NSInteger oldMin = _idxMin;
    const NSInteger oldMax = _idxMax;
    const NSInteger capacity = _capacity;
    for(NSInteger idx = newMin; idx <= newMax; ++idx) {
        if(!(oldMin <= idx && idx <= oldMax)) {
            const CGFloat value = anchor + (idx * interval);
            const CGPoint align = _textAlignment;
            NSMutableAttributedString *str = [_delegate attributedStringForValue:value dimension:dimension];
            [_buffer drawString:str toTexture:_quad.texture confBlock:^MTLRegion(CGSize lineSize, CGSize bufSize, CGRect * _Nonnull drawRect) {
                const CGFloat w = 2 * lineSize.width;
                const CGFloat h = 2 * lineSize.height;
                const CGFloat x = align.x * (bufSize.width - w);
                const CGFloat y = align.y * (bufSize.height - h);
                *drawRect = CGRectMake(x, y, w, h);
                NSInteger wrapped_idx = (idx % capacity);
                if(wrapped_idx < 0) wrapped_idx += capacity;
                return MTLRegionMake2D(0, (wrapped_idx * bufSize.height), bufSize.width, bufSize.height);
            }];
        }
    }
    
	_idxMax = newMax;
	_idxMin = newMin;
}

@end

@interface FMAxisLabelBlockDelegate()

@property (copy, nonatomic) FMAxisLabelDelegateBlock block;

@end

@implementation FMAxisLabelBlockDelegate

- (instancetype)initWithBlock:(FMAxisLabelDelegateBlock)block
{
    self = [super init];
    if(self) {
        self.block = block;
    }
    return self;
}

- (NSMutableAttributedString *)attributedStringForValue:(CGFloat)value
                                       dimension:(FMDimensionalProjection *)dimension
{
    return _block(value, dimension);
}

@end


















