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
    CGSize _defaultPopUpViewSize; // size that fits string ‘100%’
    CGSize _popUpViewSize; // usually == _defaultPopUpViewSize, but can vary if dataSource is used
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

- (void)setPopUpViewCornerRadius:(CGFloat)popUpViewCornerRadius
{
    _popUpViewCornerRadius = popUpViewCornerRadius;
    [self.popUpView setCornerRadius:popUpViewCornerRadius];
}

- (void)setAlwaysShowPopUpView:(BOOL)show
{
    _alwaysShowPopUpView = show;
    if (show && !_popUpViewIsVisible) {
        [self showPopUpView];
    } else if (!show && _popUpViewIsVisible && (self.progress == 0.0 || self.progress >= 1.0)) {
        [self hidePopUpView];
    }
}

- (void)setDataSource:(id<ASProgressPopUpViewDataSource>)dataSource
{
    _dataSource = dataSource;;
    [self calculatePopUpViewSize];
}

#pragma mark - ASPopUpViewDelegate

- (void)colorDidUpdate;
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

    self.popUpViewCornerRadius = 4.0;
    self.popUpView.alpha = 0.0;
    self.popUpView.delegate = self;
    [self addSubview:self.popUpView];

    self.textColor = [UIColor whiteColor];
    self.font = [UIFont boldSystemFontOfSize:24.0f];
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
    [self popUpViewProgress:self.progress popUpViewInfo:^(CGRect frame, CGFloat arrowOffset, NSString *popUpText) {
        [self.popUpView setFrame:frame
                     arrowOffset:arrowOffset
                           text:popUpText
                 animationOffset:self.progress];
    }];
    
    [self autoColorTrack];
}

- (void)popUpViewProgress:(float)progress
            popUpViewInfo:(void (^)(CGRect frame, CGFloat arrowOffset, NSString *popUpText))popUpViewInfo
{
    NSString *progressString; // ask dataSource for string, if nil get string from _numberFormatter
    progressString = [self.dataSource progressView:self stringForProgress:progress] ?: [_numberFormatter stringFromNumber:@(progress)];
    
    // set _popUpViewSize to appropriate size for the progressString if required
    if ([self.dataSource respondsToSelector:@selector(progressViewShouldPreCalculatePopUpViewSize:)]) {
        if ([self.dataSource progressViewShouldPreCalculatePopUpViewSize:self] == NO) {
            if ([self.dataSource progressView:self stringForProgress:progress]) {
                _popUpViewSize = [self.popUpView popUpSizeForString:progressString];
            } else {
                _popUpViewSize = _defaultPopUpViewSize;
            }
        }
    }
    
    // calculate the popUpView frame
    CGRect bounds = self.bounds;
    CGFloat xPos = (CGRectGetWidth(bounds) * progress) - _popUpViewSize.width/2;
    
    CGRect popUpRect = CGRectMake(xPos, CGRectGetMinY(bounds)-_popUpViewSize.height,
                                  _popUpViewSize.width, _popUpViewSize.height);
    
    // determine if popUpRect extends beyond the frame of the progress view
    // if so adjust frame and set the center offset of the PopUpView's arrow
    CGFloat minOffsetX = CGRectGetMinX(popUpRect);
    CGFloat maxOffsetX = CGRectGetMaxX(popUpRect) - CGRectGetWidth(bounds);
    
    CGFloat offset = minOffsetX < 0.0 ? minOffsetX : (maxOffsetX > 0.0 ? maxOffsetX : 0.0);
    popUpRect.origin.x -= offset;
    
    // call the block with 'frame', 'arrowOffset', 'popUpLabel' arguments
    popUpViewInfo(CGRectIntegral(popUpRect), offset, progressString);
}

- (void)autoColorTrack
{
    if (_autoAdjustTrackColor == NO || !_popUpViewAnimatedColors) return;

    super.progressTintColor = [self.popUpView opaqueColor];
}

- (void)calculatePopUpViewSize
{
    _defaultPopUpViewSize = [self.popUpView popUpSizeForString:[_numberFormatter stringFromNumber:@1.0]];;

    // if there isn't a dataSource, set _popUpViewSize to _defaultPopUpViewSize
    if (!self.dataSource) {
        _popUpViewSize = _defaultPopUpViewSize;
        return;
    }
    
    // if dataSource doesn't want popUpView size precalculated then return early from method
    if ([self.dataSource respondsToSelector:@selector(progressViewShouldPreCalculatePopUpViewSize:)]) {
        if ([self.dataSource progressViewShouldPreCalculatePopUpViewSize:self] == NO) return;
    }
    
    // calculate the largest popUpView size needed to keep the size consistent
    // ask the dataSource for values between 0.0 - 1.0 in 0.01 increments
    // set size to the largest width and height returned from the dataSource
    CGFloat width = 0.0, height = 0.0;
    for (int i=0; i<=100; i++) {
        NSString *string = [self.dataSource progressView:self stringForProgress:i/100.0];
        if (string) {
            CGSize size = [self.popUpView popUpSizeForString:string];
            if (size.width > width) width = size.width;
            if (size.height > height) height = size.height;
        }
    }
    _popUpViewSize = (width > 0.0 && height > 0.0) ? CGSizeMake(width, height) : _defaultPopUpViewSize;
}

- (void)showPopUpView
{
    [self.delegate progressViewWillDisplayPopUpView:self];
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
              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
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

- (void)setProgress:(float)progress animated:(BOOL)animated
{
    if (animated == NO) { // set progress without animation and return early
        self.progress = progress;
        return;
    }
    
    progress = MAX(0, MIN(progress, 1.0)); // ensure progress is in the range 0.0 - 1.0
    
    if (!_popUpViewIsVisible) [self showPopUpView];
    
    [UIView animateWithDuration:0.5 animations:^{
        [self popUpViewProgress:progress popUpViewInfo:^(CGRect frame, CGFloat arrowOffset, NSString *popUpText) {
            [self.popUpView animateFrame:frame
                             arrowOffset:arrowOffset
                                    text:popUpText
                         animationOffset:progress
                                duration:0.5
                              completion:^(UIColor *endColor) {
                                  if (endColor) super.progressTintColor = endColor;
                                  if (progress >=1.0 && !_alwaysShowPopUpView) [self hidePopUpView];
                              }];
        }];
        [super setProgress:progress animated:animated];
    }];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == ASProgressPopUpViewContext) {
        
        [self positionAndUpdatePopUpView];

        if (!_popUpViewIsVisible && self.progress > 0.0) {
            [self showPopUpView];
        } else if (self.progress >= 1.0 || self.progress <= 0.0) {
            if (_alwaysShowPopUpView == NO) [self hidePopUpView];
        }
        
    } else if (context == ASProgressViewBoundsContext) {
        [self positionAndUpdatePopUpView];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
