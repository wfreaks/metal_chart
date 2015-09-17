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
    const float sx = region.size.width / size.width;
    const float sy = region.size.height / size.height;
    CGContextRef context = CGBitmapContextCreate(_data, region.size.width, region.size.height, 8, 4 * region.size.width, _cgSpace, kCGImageAlphaPremultipliedLast);
//    CGContextScaleCTM(context, sx, sy);
    CGContextSetTextPosition(context, 0, 0);
    CTLineDraw(line, context);
    
    CGContextRelease(context);
    CFRelease(line);
    
    [texture replaceRegion:region mipmapLevel:0 withBytes:_data bytesPerRow:region.size.width * 4];
    
//    memset(_data, 0, 4 * size.width * size.height);
}

@end


@implementation MCText

- (instancetype)initWithEngine:(Engine *)engine
{
	self = [super init];
	if(self) {
		_engine = engine;
		MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm width:320 height:360 mipmapped:NO];
		id<MTLTexture> texture = [engine.resource.device newTextureWithDescriptor:desc];
		_quad = [[TextureQuad alloc] initWithEngine:engine texture:texture];
		_buffer = [[MCTextBuffer alloc] initWithBufferSize:CGSizeMake(320, 120)];
		_buffer.font = [UIFont systemFontOfSize:14];
	}
	return self;
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
			  axis:(MCAxis *)axis projection:(UniformProjection *)projection
{
	[_quad encodeWith:encoder projection:projection count:1];
}

@end
















