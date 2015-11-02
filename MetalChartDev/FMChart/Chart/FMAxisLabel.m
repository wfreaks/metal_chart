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

@interface FMLineRenderer()

@property (assign, nonatomic) void * data;
@property (assign, nonatomic) CTFontRef ctFont;
@property (assign, nonatomic) CGColorSpaceRef cgSpace;
@property (readonly, nonatomic) CGFloat scale;

@end

@implementation FMLineRenderer

- (instancetype)initWithPixelWidth:(NSUInteger)width height:(NSUInteger)height
{
    self = [super init];
    if(self) {
        _bufferPixelSize = CGSizeMake(width, height);
        _scale = [UIScreen mainScreen].scale;
        _bufferSize = CGSizeMake(width / _scale, height / _scale);
        _cgSpace = CGColorSpaceCreateDeviceRGB();
        _data = malloc(4 * width * height);
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

- (void)drawLine:(NSMutableAttributedString *)line
       toTexture:(id<MTLTexture>)texture
          region:(MTLRegion)region
       confBlock:(FMLineConfBlock)block
{
    CTFontRef font = _ctFont;
    if(font) {
        [line addAttribute:(NSString *)kCTFontAttributeName
                     value:(__bridge id)font
                     range:NSMakeRange(0, line.length)];
    }
    CTLineRef ctline = CTLineCreateWithAttributedString((CFAttributedStringRef)line);
    
    const CGRect glyphRect = CTLineGetBoundsWithOptions(ctline, kCTLineBoundsUseGlyphPathBounds);
    const CGSize bufPxSize = _bufferPixelSize;
    const CGSize bufLogSize = _bufferSize;
    CGRect drawRect;
    block(0, glyphRect.size, bufLogSize, &drawRect);
    const float sx = (drawRect.size.width) / glyphRect.size.width;
    const float sy = (drawRect.size.height) / glyphRect.size.height;
    CGContextRef context = CGBitmapContextCreate(_data, bufPxSize.width, bufPxSize.height, 8, 4 * bufPxSize.width, _cgSpace, kCGImageAlphaPremultipliedLast);
    CGContextClearRect(context, CGRectMake(0, 0, bufPxSize.width, bufPxSize.height));
    CGContextScaleCTM(context, _scale, _scale);
    CGContextTranslateCTM(context, drawRect.origin.x , drawRect.origin.y);
    CGContextScaleCTM(context, sx, sy);
    CGContextTranslateCTM(context, -glyphRect.origin.x, -glyphRect.origin.y);
    CGContextSetTextPosition(context, 0, 0);
    CTLineDraw(ctline, context);
    
    CGContextRelease(context);
    CFRelease(ctline);
    
    [texture replaceRegion:region mipmapLevel:0 withBytes:_data bytesPerRow:bufPxSize.width * 4];
}

- (void)drawLines:(NSArray<NSMutableAttributedString *> *)lines
        toTexture:(id<MTLTexture>)texture
           region:(MTLRegion)region
        confBlock:(FMLineConfBlock)block
{
    const CGSize bufPxSize = _bufferPixelSize;
    const CGSize bufLogSize = _bufferSize;
    CGContextRef context = CGBitmapContextCreate(_data, bufPxSize.width, bufPxSize.height, 8, 4 * bufPxSize.width, _cgSpace, kCGImageAlphaPremultipliedLast);
    CGContextClearRect(context, CGRectMake(0, 0, bufPxSize.width, bufPxSize.height));
    CGContextScaleCTM(context, _scale, _scale);
    const CTFontRef font = _ctFont;
    const NSUInteger count = lines.count;
    for( NSUInteger i = 0; i < count; ++i ) {
        CGContextSaveGState(context);
        NSMutableAttributedString *line = lines[count-i-1];
        if(font) {
            [line addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)font range:NSMakeRange(0, line.length)];
        }
        CTLineRef ctline = CTLineCreateWithAttributedString((CFAttributedStringRef)line);
        
        const CGRect glyphRect = CTLineGetBoundsWithOptions(ctline, kCTLineBoundsUseGlyphPathBounds);
        CGRect drawRect;
        block(i, glyphRect.size, bufLogSize, &drawRect);
        const float sx = (drawRect.size.width) / glyphRect.size.width;
        const float sy = (drawRect.size.height) / glyphRect.size.height;
        CGContextTranslateCTM(context, drawRect.origin.x , drawRect.origin.y);
        CGContextScaleCTM(context, sx, sy);
        CGContextTranslateCTM(context, -glyphRect.origin.x, -glyphRect.origin.y);
        CGContextSetTextPosition(context, 0, 0);
        CTLineDraw(ctline, context);
        CFRelease(ctline);
        CGContextRestoreGState(context);
    }
    
    CGContextRelease(context);
    
    [texture replaceRegion:region mipmapLevel:0 withBytes:_data bytesPerRow:bufPxSize.width * 4];
}

@end


@interface FMAxisLabel()

@property (readonly, nonatomic) FMLineRenderer * _Nonnull buffer;
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
        const CGSize bufSize = CGSizeMake(ceil(scale * frameSize.width), ceil(scale * frameSize.height));
		MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm width:bufSize.width height:bufSize.height * capacity mipmapped:NO];
		id<MTLTexture> texture = [engine.resource.device newTextureWithDescriptor:desc];
		_quad = [[TextureQuad alloc] initWithEngine:engine texture:texture];
		_buffer = [[FMLineRenderer alloc] initWithPixelWidth:bufSize.width height:bufSize.height];
        _capacity = capacity;
        _delegate = delegate;
        _idxMin = 1;
        _idxMax = -1;
        _textAlignment = CGPointMake(0.5, 0.5);
        _lineSpace = 2;
        
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

- (void)clearCache
{
    _idxMax = -1;
    _idxMin = 0;
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
        [self clearCache];
        return YES;
    }];
    [texRegion setIterationOffset:newMin];
    [dataRegion setIterationOffset:newMin];
    [dataRegion setBasePosition:(conf.dimensionIndex == 0) ? CGPointMake(tVal, aVal) : CGPointMake(aVal, tVal)];
    
    const NSInteger oldMin = _idxMin;
    const NSInteger oldMax = _idxMax;
    const NSInteger capacity = _capacity;
    const CGSize bufPixels = _buffer.bufferPixelSize;
    const CGPoint align = _textAlignment;
    
    for(NSInteger idx = newMin; idx <= newMax; ++idx) {
        if(!(oldMin <= idx && idx <= oldMax)) {
            const CGFloat value = anchor + (idx * interval);
            NSArray<NSMutableAttributedString*> *str = [_delegate attributedStringForValue:value dimension:dimension];
            NSInteger wrapped_idx = (idx % capacity);
            if(wrapped_idx < 0) wrapped_idx += capacity;
            const MTLRegion region = MTLRegionMake2D(0, (wrapped_idx * bufPixels.height), bufPixels.width, bufPixels.height);
            const NSUInteger count = str.count;
            [_buffer drawLines:str toTexture:_quad.texture region:region confBlock:^(NSUInteger idx, CGSize lineSize, CGSize bufSize, CGRect * _Nonnull drawRect) {
                const CGFloat w = lineSize.width;
                const CGFloat h = lineSize.height;
                const CGFloat space = self.lineSpace;
                const CGFloat boxHeight = h * count + (space * (count-1));
                const CGFloat x = align.x * (bufSize.width - w);
                const CGFloat y = align.y * (bufSize.height - boxHeight);
                const CGFloat yOffset = (h+space) * idx;
                *drawRect = CGRectMake(x, y+yOffset, w, h);
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

- (NSArray<NSMutableAttributedString*> *)attributedStringForValue:(CGFloat)value
                                       dimension:(FMDimensionalProjection *)dimension
{
    return _block(value, dimension);
}

@end


















