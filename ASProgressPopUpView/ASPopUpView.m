//
//  ASPopUpView.m
//  ASProgressPopUpView
//
//  Created by Alan Skipp on 27/03/2014.
//  Copyright (c) 2014 Alan Skipp. All rights reserved.
//

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// This UIView subclass is used internally by ASProgressPopUpView
// The public API is declared in ASProgressPopUpView.h
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


@implementation CALayer (ASAnimationAdditions)

- (void)animateKey:(NSString *)animationName fromValue:(id)fromValue toValue:(id)toValue
         customize:(void (^)(CABasicAnimation *animation))block
{
    [self setValue:toValue forKey:animationName];
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:animationName];
    anim.fromValue = fromValue ?: [self.presentationLayer valueForKey:animationName];
    anim.toValue = toValue;
    if (block) block(anim);
    [self addAnimation:anim forKey:animationName];
}

- (void)animateKey:(NSString *)animationName toValue:(id)toValue
{
    [self animateKey:animationName fromValue:nil toValue:toValue customize:nil];
}

@end


#import "ASPopUpView.h"

const float ARROW_LENGTH = 13.0;
const float POPUPVIEW_WIDTH_PAD = 1.15;
const float POPUPVIEW_HEIGHT_PAD = 1.1;

NSString *const FillColorAnimation = @"fillColor";

@implementation ASPopUpView
{
    NSMutableAttributedString *_attributedString;
    CAShapeLayer *_backgroundLayer;
    CATextLayer *_textLayer;
    CGSize _oldSize;
    CGFloat _arrowCenterOffset;
    
    // never actually visible, its purpose is to interpolate color values for the popUpView color animation
    // using shape layer because it has a 'fillColor' property which is consistent with _backgroundLayer
    CAShapeLayer *_colorAnimLayer;
}

#pragma mark - public

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.anchorPoint = CGPointMake(0.5, 1);
        
        self.userInteractionEnabled = NO;
        _backgroundLayer = [CAShapeLayer layer];
        _backgroundLayer.anchorPoint = CGPointMake(0, 0);
        
        _textLayer = [CATextLayer layer];
        _textLayer.alignmentMode = kCAAlignmentCenter;
        _textLayer.anchorPoint = CGPointMake(0, 0);
        _textLayer.contentsScale = [UIScreen mainScreen].scale;
        _textLayer.actions = @{@"bounds" : [NSNull null],   // prevent implicit animation of bounds
                               @"position" : [NSNull null]};// and position
        
        _colorAnimLayer = [CAShapeLayer layer];
        
        [self.layer addSublayer:_colorAnimLayer];
        [self.layer addSublayer:_backgroundLayer];
        [self.layer addSublayer:_textLayer];
        
        _attributedString = [[NSMutableAttributedString alloc] initWithString:@" " attributes:nil];
    }
    return self;
}

- (void)setCornerRadius:(CGFloat)radius
{
    if (_cornerRadius == radius) return;
    _cornerRadius = radius;
    _backgroundLayer.path = [self pathForRect:self.bounds withArrowOffset:_arrowCenterOffset].CGPath;
}

- (UIColor *)color
{
    return [UIColor colorWithCGColor:[_backgroundLayer.presentationLayer fillColor]];
}

- (void)setColor:(UIColor *)color
{
    _backgroundLayer.fillColor = color.CGColor;
    [_colorAnimLayer removeAnimationForKey:FillColorAnimation]; // single color, no animation required
}

- (UIColor *)opaqueColor
{
    return opaqueUIColorFromCGColor([_colorAnimLayer.presentationLayer fillColor] ?: _backgroundLayer.fillColor);
}

- (void)setTextColor:(UIColor *)color
{
    [_attributedString addAttribute:NSForegroundColorAttributeName
                                  value:(id)color.CGColor
                                  range:NSMakeRange(0, [_attributedString length])];
}

- (void)setFont:(UIFont *)font
{
    [_attributedString addAttribute:NSFontAttributeName
                                  value:font
                                  range:NSMakeRange(0, [_attributedString length])];
}

- (void)setText:(NSString *)string
{
    [[_attributedString mutableString] setString:string];
    _textLayer.string = _attributedString;
}

// set up an animation, but prevent it from running automatically
// the animation progress will be adjusted manually
- (void)setAnimatedColors:(NSArray *)animatedColors withKeyTimes:(NSArray *)keyTimes
{
    NSMutableArray *cgColors = [NSMutableArray array];
    for (UIColor *col in animatedColors) {
        [cgColors addObject:(id)col.CGColor];
    }
    
    CAKeyframeAnimation *colorAnim = [CAKeyframeAnimation animationWithKeyPath:FillColorAnimation];
    colorAnim.keyTimes = keyTimes;
    colorAnim.values = cgColors;
    colorAnim.fillMode = kCAFillModeBoth;
    colorAnim.duration = 1.0;
    colorAnim.delegate = self;
    
    // As the interpolated color values from the presentationLayer are needed immediately
    // the animation must be allowed to start to initialize _colorAnimLayer's presentationLayer
    // hence the speed is set to min value - then set to zero in 'animationDidStart:' delegate method
    _colorAnimLayer.speed = FLT_MIN;
    _colorAnimLayer.timeOffset = 0.0;
    
    [_colorAnimLayer addAnimation:colorAnim forKey:FillColorAnimation];
}

- (void)setFrame:(CGRect)frame
     arrowOffset:(CGFloat)arrowOffset
            text:(NSString *)text
 animationOffset:(CGFloat)animOffset
{
    CGFloat anchorX = 0.5+(arrowOffset/CGRectGetWidth(frame));
    self.layer.anchorPoint = CGPointMake(anchorX, 1);
    self.layer.position = CGPointMake(CGRectGetMinX(frame) + CGRectGetWidth(frame)*anchorX, 0);
    self.layer.bounds = (CGRect){CGPointZero, frame.size};

    _backgroundLayer.path = [self pathForRect:self.bounds withArrowOffset:arrowOffset].CGPath;
    [self setText:text];
    
    if ([_colorAnimLayer animationForKey:FillColorAnimation]) {
        _colorAnimLayer.timeOffset = animOffset;
        _backgroundLayer.fillColor = [_colorAnimLayer.presentationLayer fillColor];
    }
}

- (void)animateFrame:(CGRect)frame
         arrowOffset:(CGFloat)arrowOffset
                text:(NSString *)text
     animationOffset:(CGFloat)animOffset
            duration:(NSTimeInterval)duration
          completion:(void (^)(UIColor *endColor))completion
{
    [CATransaction begin]; {
        UIColor *toColor;
        if ([_colorAnimLayer animationForKey:FillColorAnimation]) {
            _colorAnimLayer.timeOffset = animOffset;
            toColor = [UIColor colorWithCGColor:[_colorAnimLayer.presentationLayer fillColor]];
        }
        
        [CATransaction setCompletionBlock:^{
            if (completion) completion(toColor);
        }];
        
        [CATransaction setAnimationDuration:duration];
        [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        
        if (toColor) [_backgroundLayer animateKey:@"fillColor" toValue:(__bridge id)toColor.CGColor];
        
        [self setText:text];

        CGFloat anchorX = 0.5+(arrowOffset/CGRectGetWidth(frame));
        [self.layer animateKey:@"anchorPoint" toValue:[NSValue valueWithCGPoint:CGPointMake(anchorX, 1)]];
        
        CGPoint toPosition = CGPointMake(CGRectGetMinX(frame) + CGRectGetWidth(frame)*anchorX, 0);
        [self.layer animateKey:@"position" toValue:[NSValue valueWithCGPoint:toPosition]];
        
        [self.layer animateKey:@"bounds" toValue:[NSValue valueWithCGRect:(CGRect){CGPointZero, frame.size}]];
        
        [_backgroundLayer animateKey:@"path"
                             toValue:(__bridge id)[self pathForRect:frame withArrowOffset:arrowOffset].CGPath];
    } [CATransaction commit];
}

- (CGSize)popUpSizeForString:(NSString *)string
{
    [[_attributedString mutableString] setString:string];
    CGFloat w, h;
    w = ceilf([_attributedString size].width * POPUPVIEW_WIDTH_PAD);
    h = ceilf(([_attributedString size].height * POPUPVIEW_HEIGHT_PAD) + ARROW_LENGTH);
    return CGSizeMake(w, h);
}

- (void)show
{
    [CATransaction begin]; {
        // start the transform animation from scale 0.5, or its current value if it's already running
        NSValue *fromValue = [self.layer animationForKey:@"transform"] ? [self.layer.presentationLayer valueForKey:@"transform"] : [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.5, 0.5, 1)];
        
        [self.layer animateKey:@"transform" fromValue:fromValue toValue:[NSValue valueWithCATransform3D:CATransform3DIdentity]
                     customize:^(CABasicAnimation *animation) {
                         animation.duration = 0.8;
                         animation.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.8 :2.5 :0.35 :0.5];
         }];
        
        [self.layer animateKey:@"opacity" fromValue:nil toValue:@1.0 customize:^(CABasicAnimation *animation) {
            animation.duration = 0.1;
        }];
        
    } [CATransaction commit];
}

- (void)hide
{
    [CATransaction begin]; {
        [CATransaction setCompletionBlock:^{ [self.delegate popUpViewDidHide]; }];

        [self.layer animateKey:@"transform" fromValue:nil
                       toValue:[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.5, 0.5, 1)]
                     customize:^(CABasicAnimation *animation) {
                         animation.duration = 0.9;
                         animation.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.1 :-2 :0.3 :3];
         }];
        
        [self.layer animateKey:@"opacity" fromValue:nil toValue:@0.0 customize:^(CABasicAnimation *animation) {
            animation.duration = 1.0;
        }];
        
    } [CATransaction commit];
}

#pragma mark - CAAnimation delegate

// set the speed to zero to freeze the animation and set the offset to the correct value
// the animation can now be updated manually by explicity setting its 'timeOffset'
- (void)animationDidStart:(CAAnimation *)animation
{
    _colorAnimLayer.speed = 0.0;
    _colorAnimLayer.timeOffset = [self.delegate currentValueOffset];
    
    _backgroundLayer.fillColor = [_colorAnimLayer.presentationLayer fillColor];
    [self.delegate colorDidUpdate];
}

#pragma mark - private

- (UIBezierPath *)pathForRect:(CGRect)rect withArrowOffset:(CGFloat)arrowOffset;
{
    if (CGRectEqualToRect(rect, CGRectZero)) return nil;
    
    rect = (CGRect){CGPointZero, rect.size}; // ensure origin is CGPointZero

    // Create rounded rect
    CGRect roundedRect = rect;
    roundedRect.size.height -= ARROW_LENGTH;
    UIBezierPath *popUpPath = [UIBezierPath bezierPathWithRoundedRect:roundedRect cornerRadius:_cornerRadius];
    
    // Create arrow path
    CGFloat maxX = CGRectGetMaxX(roundedRect); // prevent arrow from extending beyond this point
    CGFloat arrowTipX = CGRectGetMidX(rect) + arrowOffset;
    CGPoint tip = CGPointMake(arrowTipX, CGRectGetMaxY(rect));
    
    CGFloat arrowLength = CGRectGetHeight(roundedRect)/2.0;
    CGFloat x = arrowLength * tan(45.0 * M_PI/180); // x = half the length of the base of the arrow
    
    UIBezierPath *arrowPath = [UIBezierPath bezierPath];
    [arrowPath moveToPoint:tip];
    [arrowPath addLineToPoint:CGPointMake(MAX(arrowTipX - x, 0), CGRectGetMaxY(roundedRect) - arrowLength)];
    [arrowPath addLineToPoint:CGPointMake(MIN(arrowTipX + x, maxX), CGRectGetMaxY(roundedRect) - arrowLength)];
    [arrowPath closePath];
    
    [popUpPath appendPath:arrowPath];
    
    return popUpPath;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (CGSizeEqualToSize(self.bounds.size, _oldSize)) return; // return if view size hasn't changed
    
    _oldSize = self.bounds.size;
    _backgroundLayer.bounds = self.bounds;
    
    CGFloat textHeight = [_textLayer.string size].height;
    CGRect textRect = CGRectMake(self.bounds.origin.x,
                                 (self.bounds.size.height-ARROW_LENGTH-textHeight)/2,
                                 self.bounds.size.width, textHeight);
    _textLayer.frame = CGRectIntegral(textRect);
}

static UIColor* opaqueUIColorFromCGColor(CGColorRef col)
{
    if (col == NULL) return nil;
    
    const CGFloat *components = CGColorGetComponents(col);
    UIColor *color;
    if (CGColorGetNumberOfComponents(col) == 2) {
        color = [UIColor colorWithWhite:components[0] alpha:1.0];
    } else {
        color = [UIColor colorWithRed:components[0] green:components[1] blue:components[2] alpha:1.0];
    }
    return color;
}

@end
