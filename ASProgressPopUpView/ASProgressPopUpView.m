//
//  ASProgressPopUpView.h
//  ASProgressPopUpView
//
//  Created by Alan Skipp on 19/10/2013.
//  Copyright (c) 2013 Alan Skipp. All rights reserved.
//

#import "ASPopUpView.h"
#import "ASProgressPopUpView.h"

@interface ASProgressPopUpView() <ASPopUpViewDelegate>
@property (strong, nonatomic) NSNumberFormatter *numberFormatter;
@property (strong, nonatomic) ASPopUpView *popUpView;
@end

@implementation ASProgressPopUpView
{
    UIColor *_popUpViewColor;
    NSArray *_keyTimes;
    BOOL _shouldAnimate;
    CALayer *_progressLayer;
    CAGradientLayer *_gradientLayer;
}

#pragma mark - initialization

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

#pragma mark - public

- (void)showPopUpViewAnimated:(BOOL)animated
{
    if (self.popUpView.alpha == 1.0) return;
    
    [self.delegate progressViewWillDisplayPopUpView:self];
    [self.popUpView showAnimated:animated];
}

- (void)hidePopUpViewAnimated:(BOOL)animated
{
    if (self.popUpView.alpha == 0.0) return;
    
    [self.popUpView hideAnimated:animated completionBlock:^{
        if ([self.delegate respondsToSelector:@selector(progressViewDidHidePopUpView:)]) {
            [self.delegate progressViewDidHidePopUpView:self];
        }
    }];
}

- (void)setTextColor:(UIColor *)color
{
    _textColor = color;
    [self.popUpView setTextColor:color];
}

- (void)setFont:(UIFont *)font
{
    NSAssert(font, @"font can not be nil, it must be a valid UIFont");
    _font = font;
    [self.popUpView setFont:font];
}

- (void)setTrackTintColor:(UIColor *)color
{
    self.backgroundColor = color;
}

- (UIColor *)trackTintColor
{
    return self.backgroundColor;
}

// return the currently displayed color if possible, otherwise return _popUpViewColor
// if animated colors are set, the color will change each time the progress view updates
- (UIColor *)popUpViewColor
{
    return [self.popUpView color] ?: _popUpViewColor;
}

- (void)setPopUpViewColor:(UIColor *)color
{
    _popUpViewColor = color;
    _popUpViewAnimatedColors = nil; // animated colors should be discarded
    [self.popUpView setColor:color];
    [self setGradientColors:@[color, color] withPositions:nil];
}

- (void)setPopUpViewAnimatedColors:(NSArray *)colors
{
    [self setPopUpViewAnimatedColors:colors withPositions:nil];
}

// if 2 or more colors are present, set animated colors
// if only 1 color is present then call 'setPopUpViewColor:'
// if arg is nil then restore previous _popUpViewColor
- (void)setPopUpViewAnimatedColors:(NSArray *)colors withPositions:(NSArray *)positions
{
    if (positions) {
        NSAssert([colors count] == [positions count], @"popUpViewAnimatedColors and locations should contain the same number of items");
    }
    
    _popUpViewAnimatedColors = colors;
    _keyTimes = positions;
    
    if ([colors count] >= 2) {
        [self.popUpView setAnimatedColors:colors withKeyTimes:_keyTimes];
        [self setGradientColors:colors withPositions:positions];
    } else {
        [self setGradientColors:colors withPositions:positions];
//        [self setPopUpViewColor:[colors lastObject] ?: _popUpViewColor];
    }
}

- (void)setPopUpViewCornerRadius:(CGFloat)radius
{
    self.popUpView.cornerRadius = radius;
}

- (CGFloat)popUpViewCornerRadius
{
    return self.popUpView.cornerRadius;
}

- (void)setDataSource:(id<ASProgressPopUpViewDataSource>)dataSource
{
    _dataSource = dataSource;
    self.continuouslyAdjustPopUpViewSize = YES;
}

// returns the current progress in the range 0.0 – 1.0
- (CGFloat)currentValueOffset
{
    return self.progress;
}

#pragma mark - private

- (void)setup
{
    _progressLayer = [CALayer layer];
    _progressLayer.masksToBounds = YES;
    _progressLayer.anchorPoint = CGPointMake(0, 0);
    [self.layer addSublayer:_progressLayer];
    
    _gradientLayer = [CAGradientLayer layer];
    _gradientLayer.startPoint = CGPointZero;
    _gradientLayer.endPoint = CGPointMake(1, 0);
    [_progressLayer addSublayer:_gradientLayer];
    
    self.progress = 0;
    
    _continuouslyAdjustPopUpViewSize = NO;
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterPercentStyle];
    _numberFormatter = formatter;

    self.popUpView = [[ASPopUpView alloc] initWithFrame:CGRectZero];
    self.popUpViewColor = [UIColor colorWithHue:0.6 saturation:0.6 brightness:0.5 alpha:0.8];

    self.popUpView.alpha = 0.0;
    self.popUpView.delegate = self;
    [self addSubview:self.popUpView];

    self.textColor = [UIColor whiteColor];
    self.font = [UIFont boldSystemFontOfSize:20.0f];
}

// ensure animation restarts if app is closed then becomes active again
- (void)didBecomeActiveNotification:(NSNotification *)note
{
    if (self.popUpViewAnimatedColors) {
        [self.popUpView setAnimatedColors:_popUpViewAnimatedColors withKeyTimes:_keyTimes];
    }
}

- (void)updatePopUpView
{
    NSString *progressString; // ask dataSource for string, if nil get string from _numberFormatter
    progressString = [self.dataSource progressView:self stringForProgress:self.progress] ?: [_numberFormatter stringFromNumber:@(self.progress)];
    if (progressString.length == 0) progressString = @"???"; // replacement for blank string
    
    CGSize popUpViewSize = (self.continuouslyAdjustPopUpViewSize == YES)
    ? [self.popUpView popUpSizeForString:progressString]
    : [self calculatePopUpViewSize];
    
    // calculate the popUpView frame
    CGRect bounds = self.bounds;
    CGFloat xPos = (CGRectGetWidth(bounds) * self.progress) - popUpViewSize.width/2;
    
    CGRect popUpRect = CGRectMake(xPos, CGRectGetMinY(bounds)-popUpViewSize.height,
                                  popUpViewSize.width, popUpViewSize.height);
    
    // determine if popUpRect extends beyond the frame of the progress view
    // if so adjust frame and set the center offset of the PopUpView's arrow
    CGFloat minOffsetX = CGRectGetMinX(popUpRect);
    CGFloat maxOffsetX = CGRectGetMaxX(popUpRect) - CGRectGetWidth(bounds);
    
    CGFloat offset = minOffsetX < 0.0 ? minOffsetX : (maxOffsetX > 0.0 ? maxOffsetX : 0.0);
    popUpRect.origin.x -= offset;
    
    [self.popUpView setFrame:popUpRect arrowOffset:offset colorOffset:self.progress text:progressString];

}

- (CGSize)calculatePopUpViewSize
{
    NSString *defaultString = (self.dataSource)
    ? [self.dataSource progressView:self stringForProgress:1.0]
    : [_numberFormatter stringFromNumber:@1.0];
    
    CGSize defaultPopUpViewSize = [self.popUpView popUpSizeForString:defaultString];
    if (!self.dataSource) return defaultPopUpViewSize;

    // calculate the largest popUpView size needed to keep the size consistent
    // ask the dataSource for 'allStringsForProgressView'
    // set size to the largest width and height returned from the dataSource

    CGFloat width = 0.0, height = 0.0;
    for (NSString *string in [self.dataSource allStringsForProgressView:self]) {
        CGSize size = [self.popUpView popUpSizeForString:string];
        if (size.width > width) width = size.width;
        if (size.height > height) height = size.height;
    }
    
    return (width > defaultPopUpViewSize.width) ? CGSizeMake(width, height) : defaultPopUpViewSize;
}

#pragma mark - subclassed

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self updateProgressLayer];
    [self updatePopUpView];
}

- (void)updateProgressLayer
{
    _gradientLayer.frame = self.bounds;
    _progressLayer.frame = CGRectMake(0, 0, self.bounds.size.width * self.progress, self.bounds.size.height);
}


- (void)didMoveToWindow
{
    if (!self.window) { // removed from window - cancel observers and notifications
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    else { // added to window - register observers, notifications and reset animated colors if needed
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didBecomeActiveNotification:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        
        if (self.popUpViewAnimatedColors) {
            [self.popUpView setAnimatedColors:_popUpViewAnimatedColors withKeyTimes:_keyTimes];
        }
    }
}

//- (void)setProgressTintColor:(UIColor *)color
//{
//    self.progressLayer.backgroundColor = color.CGColor;
//}
//
//- (UIColor *)progressTintColor
//{
//    return [UIColor colorWithCGColor:self.progressLayer.backgroundColor];
//}

- (void)setProgress:(float)progress
{
    _progress = MAX(0.0, MIN(progress, 1.0));
    [self updateProgressLayer];
}

- (void)setProgress:(float)progress animated:(BOOL)animated
{
    _shouldAnimate = animated;
    
    if (animated) {
        [self.popUpView animateBlock:^(CFTimeInterval duration) {
            CABasicAnimation *anim = [CABasicAnimation animation];
            anim.duration = duration;
            anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            anim.fromValue = [_progressLayer.presentationLayer valueForKey:@"bounds"];
            _progressLayer.actions = @{@"bounds" : anim};
            
            [UIView animateWithDuration:duration animations:^{
                self.progress = progress;
                [self layoutIfNeeded];
            }];
        }];
    } else {
        _progressLayer.actions = @{@"bounds" : [NSNull null]};
        self.progress = progress;
    }
}

- (void)setGradientColors:(NSArray *)gradientColors withPositions:(NSArray *)positions
{
    NSMutableArray *cgColors = [NSMutableArray array];
    for (UIColor *col in gradientColors) {
        [cgColors addObject:(id)col.CGColor];
    }
    
    _gradientLayer.colors = cgColors;
    _gradientLayer.locations = positions;
}

@end
