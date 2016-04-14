//
//  FMAxisLabel.m
//  FMChart
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
		_clearColor = 0x00FFFFFF;
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

- (void)drawLines:(NSArray<NSMutableAttributedString *> *)lines
        toTexture:(id<MTLTexture>)texture
           region:(MTLRegion)region
        confBlock:(FMLineConfBlock)block
{
    const CGSize bufPxSize = _bufferPixelSize;
    const CGSize bufLogSize = _bufferSize;
	{ // 手動で_dataをクリアしないと、CoreTextが明るい色の文字をうまく描画できなくなる。この問題は本質的には描画色を必要とするが、ひとまずこの状態にしておく.
		const int32_t color = _clearColor;
		const int num = bufPxSize.width * bufPxSize.height;
		int32_t * const ptr = (int32_t *)_data;
		for(int i = 0; i < num; ++i) ptr[i] = color;
	}
    CGContextRef context = CGBitmapContextCreate(_data, bufPxSize.width, bufPxSize.height, 8, 4 * bufPxSize.width, _cgSpace, kCGImageAlphaPremultipliedLast);
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
		[_hook willDrawString:line toContext:context drawRect:&drawRect];
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



@implementation FMBlockLineDrawHook

- (instancetype)initWithBlock:(FMLineHookBlock)block
{
	self = [super init];
	if(self) {
		_block = block;
	}
	return self;
}

- (void)willDrawString:(NSAttributedString *)string toContext:(CGContextRef)context drawRect:(const CGRect *)drawRect
{
	_block(string, context, drawRect);
}

+ (instancetype)hookWithBlock:(FMLineHookBlock)block
{
	return [[self alloc] initWithBlock:block];
}

@end



@interface FMAxisLabel()

@property (readonly, nonatomic) FMEngine *engine;
@property (readonly, nonatomic) FMLineRenderer * _Nonnull buffer;
@property (assign, nonatomic) NSInteger idxMin;
@property (assign, nonatomic) NSInteger idxMax;
@property (assign, nonatomic) NSUInteger capacity;

- (FMUniformRegion *)dataRegionForProjection:(FMProjectionCartesian2D *)projection;

@end



@interface FMSharedAxisLabel()

@property (nonatomic) CGSize  frameSize;
@property (nonatomic) CGPoint frameOffset;
@property (nonatomic) CGPoint frameAnchorPoint;
@property (nonatomic) CGPoint dataIterationVector;
@property (nonatomic) NSMutableDictionary<NSString *, FMUniformRegion *> *dataRegions;

@end



@implementation FMAxisLabel

- (instancetype)initWithEngine:(FMEngine *)engine
                     frameSize:(CGSize)frameSize
                bufferCapacity:(NSUInteger)capacity
                 labelDelegate:(id<FMAxisLabelDelegate> _Nonnull)delegate
{
	self = [super init];
	if(self) {
        _engine = engine;
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
		_textOffset = CGPointZero;
        _lineSpace = 2;
        
        self.frameSize = frameSize;
        self.frameAnchorPoint = CGPointMake(0.5, 0.5);
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

- (void)setFrameSize:(CGSize)frameSize
{
	[_quad.dataRegion setSize:frameSize];
}

- (void)setDataIterationVector:(CGPoint)vector
{
	[_quad.dataRegion setIterationVector:vector];
}

- (void)encodeWith:(id<MTLRenderCommandEncoder>)encoder
             chart:(MetalChart *)chart
              view:(FMMetalView *)view
{
    id<FMAxis> axis = _axis;
    if(axis) {
        const NSInteger count = MAX(0, (_idxMax-_idxMin) + 1);
        FMProjectionCartesian2D *projection = [axis projectionForChart:chart];
        if(projection) {
            FMUniformRegion *dataRegion = [self dataRegionForProjection:projection];
            FMUniformRegion *texRegion = _quad.texRegion;
            [_quad encodeWith:encoder projection:projection.projection count:count dataRegion:dataRegion texRegion:texRegion];
        }
    }
}

- (void)prepare:(MetalChart *)chart view:(FMMetalView *)view
{
    if(_axis) {
        [self configure:_axis chart:chart view:view];
    }
}

- (NSArray<id<FMDependentAttachment>> *)dependencies
{
    id<FMAxis> axis = _axis;
    return (axis) ? @[axis] : @[];
}

- (void)clearCache
{
    _idxMax = -1;
    _idxMin = 0;
}

- (FMUniformRegion *)dataRegionForProjection:(FMProjectionCartesian2D *)projection
{
	return _quad.dataRegion;
}

- (void)configure:(id<FMAxis>)axis chart:(MetalChart *)chart view:(MetalView *)view
{
    FMDimensionalProjection *dimension = axis.dimension;
    const CGFloat min = dimension.min;
    const CGFloat max = dimension.max;
    FMUniformAxisConfiguration *conf = axis.axis.configuration;
    const CGFloat anchor = conf.tickAnchorValue;
    const CGFloat interval = conf.majorTickInterval;
    const NSInteger newMin = ceil((min-anchor)/interval);
    const NSInteger newMax = floor((max-anchor)/interval);
    
    FMProjectionCartesian2D *proj = [axis projectionForChart:chart];
    FMUniformRegion *texRegion = _quad.texRegion;
    FMUniformRegion *dataRegion = [self dataRegionForProjection:proj];
    const CGFloat aVal = [conf axisAnchorValueWithProjection:proj.projection];
    const CGFloat tVal = conf.tickAnchorValue;
    [conf checkIfMajorTickValueModified:^BOOL(FMUniformAxisConfiguration *conf) {
        const CGFloat normHeight = 1 / (CGFloat)self.capacity;
        [texRegion setIterationVector:CGPointMake(0, normHeight)];
        [texRegion setSize:CGSizeMake(1, normHeight)];
        [self setDataIterationVector:(conf.dimensionIndex == 0) ? CGPointMake(interval, 0) : CGPointMake(0, interval)];
        [self clearCache];
        return YES;
    }];
    [texRegion setIterationOffset:newMin];
    [dataRegion setIterationOffset:newMin];
    [dataRegion setBasePosition:(conf.dimensionIndex == 0) ? CGPointMake(tVal, aVal) : CGPointMake(aVal, tVal)];
    
    const NSInteger capacity = _capacity;
    const CGSize bufPixels = _buffer.bufferPixelSize;
    const CGPoint align = _textAlignment;
	const CGPoint offset = _textOffset;
	
	NSInteger oldMin = _idxMin;
	NSInteger oldMax = _idxMax;
	const BOOL changed = (oldMin > newMin || oldMax < newMax);
	
	LabelCacheModifierBlock block = _cacheModifier;
	if(block && changed) {
		block(newMin, newMax, &oldMin, &oldMax);
	}
	
    for(NSInteger idx = newMin; idx <= newMax; ++idx) {
        if(!(oldMin <= idx && idx <= oldMax)) {
			const CGFloat value = anchor + (idx * interval);
			NSArray<NSMutableAttributedString*> *str = [_delegate attributedStringForValue:value index:idx-newMin last:newMax-newMin dimension:dimension];
			NSInteger wrapped_idx = (idx % capacity);
			if(wrapped_idx < 0) wrapped_idx += capacity;
			const MTLRegion region = MTLRegionMake2D(0, (wrapped_idx * bufPixels.height), bufPixels.width, bufPixels.height);
			const NSUInteger count = str.count;
			[_buffer drawLines:str toTexture:_quad.texture region:region confBlock:^(NSUInteger idx, CGSize lineSize, CGSize bufSize, CGRect * _Nonnull drawRect) {
				const CGFloat w = lineSize.width;
				const CGFloat h = lineSize.height;
				const CGFloat space = self.lineSpace;
				const CGFloat boxHeight = h * count + (space * (count-1));
				const CGFloat x = (align.x * (bufSize.width - w)) + offset.x;
				const CGFloat y = (align.y * (bufSize.height - boxHeight)) + offset.y;
				const CGFloat yOffset = (h+space) * idx;
				*drawRect = CGRectMake(x, y+yOffset, w, h);
			}];
        }
    }
	
	_idxMax = newMax;
	_idxMin = newMin;
}

- (void)setClearColor:(int32_t)color
{
	_buffer.clearColor = color;
}

- (void)setLineDrawHook:(id<FMLineDrawHook>)hook
{
	_buffer.hook = hook;
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
                                                            index:(NSInteger)index
                                                             last:(NSInteger)lastIndex
                                                        dimension:(FMDimensionalProjection * _Nonnull)dimension
{
    return _block(value, index, lastIndex, dimension);
}

@end




@implementation FMSharedAxisLabel

- (instancetype)initWithEngine:(FMEngine *)engine
					 frameSize:(CGSize)frameSize
				bufferCapacity:(NSUInteger)capacity
				 labelDelegate:(id<FMAxisLabelDelegate>)delegate
{
	self = [super initWithEngine:engine frameSize:frameSize bufferCapacity:capacity labelDelegate:delegate];
	if(self) {
		_dataRegions = [NSMutableDictionary dictionary];
	}
	return self;
}

- (void)setFrameOffset:(CGPoint)offset
{
	if(!CGPointEqualToPoint(_frameOffset, offset)) {
		_frameOffset = offset;
		[self _synchronizeDataRegions];
	}
}

- (void)setFrameAnchorPoint:(CGPoint)point
{
	if(!CGPointEqualToPoint(_frameAnchorPoint, point)) {
		_frameAnchorPoint = point;
		[self _synchronizeDataRegions];
	}
}

- (void)setFrameSize:(CGSize)frameSize
{
	if(!CGSizeEqualToSize(_frameSize, frameSize)) {
		_frameSize = frameSize;
		[self _synchronizeDataRegions];
	}
}

- (void)setDataIterationVector:(CGPoint)vector
{
	if(!CGPointEqualToPoint(_dataIterationVector, vector)) {
		_dataIterationVector = vector;
		[self _synchronizeDataRegions];
	}
}

- (void)_synchronizeDataRegions
{
	@synchronized(self) {
		NSArray<FMUniformRegion *> *regions = _dataRegions.allValues;
		const CGPoint offset = _frameOffset, anchor = _frameAnchorPoint, iter = _dataIterationVector;
		const CGSize size = _frameSize;
		for(FMUniformRegion *r in regions) {
			[r setPositionOffset:offset];
			[r setSize:size];
			[r setIterationVector:iter];
			[r setAnchorPoint:anchor];
		}
	}
}

- (FMUniformRegion *)dataRegionForProjection:(FMProjectionCartesian2D *)projection
{
	@synchronized(self) {
		FMUniformRegion *region = self.dataRegions[projection.key];
		if(!region) {
			region = [[FMUniformRegion alloc] initWithResource:self.engine.resource];
			self.dataRegions[projection.key] = region;
			
			[region setPositionOffset:_frameOffset];
			[region setSize:_frameSize];
			[region setIterationVector:_dataIterationVector];
			[region setAnchorPoint:_frameAnchorPoint];
		}
		return region;
	}
}

@end










