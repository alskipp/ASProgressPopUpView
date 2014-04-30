//
//  ASProgressPopUpView.h
//  ASProgressPopUpView
//
//  Created by Alan Skipp on 19/10/2013.
//  Copyright (c) 2013 Alan Skipp. All rights reserved.
//

#import "ASPopUpView.h"
#import "ASProgressPopUpView.h"

static void * ASProgressPopUpViewContext = &ASProgressPopUpViewContext;
static void * ASProgressViewBoundsContext = &ASProgressViewBoundsContext;

@interface ASProgressPopUpView() <ASPopUpViewDelegate>
@property (strong, nonatomic) NSNumberFormatter *numberFormatter;
@property (strong, nonatomic) ASPopUpView *popUpView;
@end

@implementation ASProgressPopUpView
{
    CGSize _popUpViewSize;
    UIColor *_popUpViewColor;
    NSArray *_keyTimes;
    BOOL _popUpViewIsVisible;
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

- (void)setDelegate:(id<ASProgressPopUpViewDelegate>)delegate
{
    _delegate = delegate;
    
    if ([self.delegate respondsToSelector:@selector(progressView:stringForProgress:)]) {
        CGFloat width = 0.0, height = 0.0;
        for (float i=0.0; i<1.1; i+=0.1) {
            CGSize s = [self.popUpView popUpSizeForString:[self.delegate progressView:self stringForProgress:i]];
            if (s.width > width) width = s.width;
            if (s.height > height) height = s.height;
        }
        _popUpViewSize = CGSizeMake(width, height);
    }
}

- (void)setAutoAdjustTrackColor:(BOOL)autoAdjust
{
    if (_autoAdjustTrackColor == autoAdjust) return;
    
    _autoAdjustTrackColor = autoAdjust;
    
    // setMinimumTrackTintColor has been overridden to also set autoAdjustTrackColor to NO
    // therefore super's implementation must be called to set minimumTrackTintColor
    if (autoAdjust == NO) {
        super.progressTintColor = nil; // sets track to default blue color
    } else {
        super.progressTintColor = [self.popUpView opaqueColor];
    }
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

    [self calculatePopUpViewSize];
}

// return the currently displayed color if possible, otherwise return _popUpViewColor
// if animated colors are set, the color will change each time the progress view updates
- (UIColor *)popUpViewColor
{
    return [self.popUpView color] ?: _popUpViewColor;
}

- (void)setPopUpViewColor:(UIColor *)popUpViewColor
{
    _popUpViewColor = popUpViewColor;
    _popUpViewAnimatedColors = nil; // animated colors should be discarded
    [self.popUpView setColor:popUpViewColor];

    if (_autoAdjustTrackColor) {
        super.progressTintColor = [self.popUpView opaqueColor];
    }
}

- (void)setPopUpViewAnimatedColors:(NSArray *)popUpViewAnimatedColors
{
    [self setPopUpViewAnimatedColors:popUpViewAnimatedColors withPositions:nil];
}

// if 2 or more colors are present, set animated colors
// if only 1 color is present then call 'setPopUpViewColor:'
// if arg is nil then restore previous _popUpViewColor
- (void)setPopUpViewAnimatedColors:(NSArray *)popUpViewAnimatedColors withPositions:(NSArray *)positions
{
    if (positions) {
        NSAssert([popUpViewAnimatedColors count] == [positions count], @"popUpViewAnimatedColors and locations should contain the same number of items");
    }
    
    _popUpViewAnimatedColors = popUpViewAnimatedColors;
    _keyTimes = positions;
    
    if ([popUpViewAnimatedColors count] >= 2) {
        [self.popUpView setAnimatedColors:popUpViewAnimatedColors withKeyTimes:_keyTimes];
    } else {
        [self setPopUpViewColor:[popUpViewAnimatedColors lastObject] ?: _popUpViewColor];
    }
}

- (void)setAlwaysShowPopUpView:(BOOL)show
{
    _alwaysShowPopUpView = show;
    if (show && !_popUpViewIsVisible) {
        [self positionAndUpdatePopUpView];
        [self showPopUpView];
    } else if (!show && _popUpViewIsVisible && (self.progress == 0.0 || self.progress >= 1.0)) {
        [self hidePopUpView];
    }
}

#pragma mark - ASPopUpViewDelegate

- (void)colorAnimationDidStart;
{
    [self autoColorTrack];
}

- (void)popUpViewDidHide;
{
    if ([self.delegate respondsToSelector:@selector(progressViewDidHidePopUpView:)]) {
        [self.delegate progressViewDidHidePopUpView:self];
    }
}

// returns the current progress in the range 0.0 – 1.0
- (CGFloat)currentValueOffset
{
    return self.progress;
}

#pragma mark - private

- (void)setup
{
    _autoAdjustTrackColor = YES;
    _popUpViewIsVisible = NO;
    _alwaysShowPopUpView = NO;
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterPercentStyle];
    _numberFormatter = formatter;

    self.popUpView = [[ASPopUpView alloc] initWithFrame:CGRectZero];
    self.popUpViewColor = [UIColor colorWithHue:0.6 saturation:0.6 brightness:0.5 alpha:0.8];

    self.popUpView.alpha = 0.0;
    self.popUpView.delegate = self;
    [self addSubview:self.popUpView];

    self.textColor = [UIColor whiteColor];
    self.font = [UIFont boldSystemFontOfSize:24.0f];
    
    [self positionAndUpdatePopUpView];
}

// ensure animation restarts if app is closed then becomes active again
- (void)didBecomeActiveNotification:(NSNotification *)note
{
    if (self.popUpViewAnimatedColors) {
        [self.popUpView setAnimatedColors:_popUpViewAnimatedColors withKeyTimes:_keyTimes];
    }
}

- (void)positionAndUpdatePopUpView
{
    if ([self.delegate respondsToSelector:@selector(progressView:stringForProgress:)]) {

        NSString *s = [self.delegate progressView:self stringForProgress:self.progress];
//        _popUpViewSize = [self.popUpView popUpSizeForString:s];
        [self.popUpView setString:s];

    } else {
        [self.popUpView setString:[_numberFormatter stringFromNumber:@(self.progress)]];
    }
    
    [self adjustPopUpViewFrame];
    [self.popUpView setAnimationOffset:[self currentValueOffset]];
    
    [self autoColorTrack];
}

- (void)adjustPopUpViewFrame
{
    CGRect progressRect = self.bounds;
    CGFloat xPos = (CGRectGetWidth(progressRect) * self.progress) - _popUpViewSize.width/2;
    
    CGRect popUpRect = CGRectMake(xPos, CGRectGetMinY(progressRect)-_popUpViewSize.height,
                                  _popUpViewSize.width, _popUpViewSize.height);

    // determine if popUpRect extends beyond the frame of the progress view
    // if so adjust frame and set the center offset of the PopUpView's arrow
    CGFloat minOffsetX = CGRectGetMinX(popUpRect);
    CGFloat maxOffsetX = CGRectGetMaxX(popUpRect) - self.bounds.size.width;
    
    CGFloat offset = minOffsetX < 0.0 ? minOffsetX : (maxOffsetX > 0.0 ? maxOffsetX : 0.0);
    popUpRect.origin.x -= offset;
    [self.popUpView setArrowCenterOffset:offset];

    self.popUpView.frame = popUpRect;
}

- (void)autoColorTrack
{
    if (_autoAdjustTrackColor == NO || !_popUpViewAnimatedColors) return;

    super.progressTintColor = [self.popUpView opaqueColor];
}

- (void)calculatePopUpViewSize
{
    _popUpViewSize = [self.popUpView popUpSizeForString:[_numberFormatter stringFromNumber:@1.0]];
}

- (void)showPopUpView
{
    if ([self.delegate respondsToSelector:@selector(progressViewWillDisplayPopUpView:)]) {
        [self.delegate progressViewWillDisplayPopUpView:self];
    }
    [self positionAndUpdatePopUpView];
    [self.popUpView show];
    _popUpViewIsVisible = YES;
}

- (void)hidePopUpView
{
    [self.popUpView hide];
    _popUpViewIsVisible = NO;
}

- (void)addObserversAndNotifications
{
    [self addObserver:self forKeyPath:@"progress"
              options:NSKeyValueObservingOptionNew
              context:ASProgressPopUpViewContext];
    
    [self addObserver:self forKeyPath:@"bounds"
              options:NSKeyValueObservingOptionNew
              context:ASProgressViewBoundsContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didBecomeActiveNotification:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)removeObserversAndNotifications
{
    [self removeObserver:self forKeyPath:@"progress"];
    [self removeObserver:self forKeyPath:@"bounds"];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - subclassed

- (void)didMoveToWindow
{
    if (!self.window) { // removed from window - cancel observers and notifications
        [self removeObserversAndNotifications];
    }
    else { // added to window - register observers, notifications and reset animated colors if needed
        [self addObserversAndNotifications];
        if (self.popUpViewAnimatedColors) {
            [self.popUpView setAnimatedColors:_popUpViewAnimatedColors withKeyTimes:_keyTimes];
        }
    }
}

- (void)setProgressTintColor:(UIColor *)color
{
    self.autoAdjustTrackColor = NO; // if a custom value is set then prevent auto coloring
    [super setProgressTintColor:color];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == ASProgressPopUpViewContext) {
        [self positionAndUpdatePopUpView];
        
        if (!_popUpViewIsVisible && self.progress > 0.0) {
            [self showPopUpView];
        } else if (self.progress >= 1.0 && _alwaysShowPopUpView == NO) {
            [self hidePopUpView];
        }
        
    } else if (context == ASProgressViewBoundsContext) {
        if (_popUpViewIsVisible) [self positionAndUpdatePopUpView];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
