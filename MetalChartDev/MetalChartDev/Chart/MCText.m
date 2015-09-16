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
        CFRelease(_ctFont);
        _ctFont = nil;
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
    CGContextRef context = CGBitmapContextCreate(_data, region.size.width, region.size.height, 8, 4 * size.width, _cgSpace, kCGImageAlphaPremultipliedLast);
    CGContextScaleCTM(context, sx, sy);
    CGContextSetTextPosition(context, 0, 0);
    CTLineDraw(line, context);
    
    CGContextRelease(context);
    CFRelease(line);
    
    [texture replaceRegion:region mipmapLevel:0 withBytes:_data bytesPerRow:size.width * 4];
    
    memset(_data, 0, 4 * size.width * size.height);
}

@end
