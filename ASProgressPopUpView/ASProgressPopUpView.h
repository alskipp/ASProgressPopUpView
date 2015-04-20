//
//  ASProgressPopUpView.m
//  ASProgressPopUpView
//
//  Created by Alan Skipp on 27/03/2014.
//  Copyright (c) 2014 Alan Skipp. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol ASProgressPopUpViewDelegate;
@protocol ASProgressPopUpViewDataSource;

@interface ASProgressPopUpView : UIView

- (void)showPopUpViewAnimated:(BOOL)animated;
- (void)hidePopUpViewAnimated:(BOOL)animated;

@property(nonatomic) float progress;                        // 0.0 .. 1.0, default is 0.0. values outside are pinned.
//@property(strong, nonatomic) UIColor* progressTintColor;
@property(strong, nonatomic) UIColor* trackTintColor;

- (void)setProgress:(float)progress animated:(BOOL)animated;

@property (strong, nonatomic) UIColor *textColor;

// font can not be nil, it must be a valid UIFont
// default is ‘boldSystemFontOfSize:20.0’
@property (strong, nonatomic) UIFont *font;

// setting the value of 'popUpViewColor' overrides 'popUpViewAnimatedColors' and vice versa
// the return value of 'popUpViewColor' is the currently displayed value
// this will vary if 'popUpViewAnimatedColors' is set (see below)
@property (strong, nonatomic) UIColor *popUpViewColor;

// pass an array of 2 or more UIColors to animate the color change as the progress updates
@property (strong, nonatomic) NSArray *popUpViewAnimatedColors;

// the above @property distributes the colors evenly across the progress view
// to specify the exact position of colors, pass an NSArray of NSNumbers (in the range 0.0 - 1.0)
- (void)setPopUpViewAnimatedColors:(NSArray *)popUpViewAnimatedColors withPositions:(NSArray *)positions;

// radius of the popUpView, default is 4.0
@property (nonatomic) CGFloat popUpViewCornerRadius;


// by default the popUpView size will be static and calculated to fit the largest display value
// to have the size continuously adjust set the property to YES
// if you set a dataSource the property will automatically be set to YES
@property (nonatomic) BOOL continuouslyAdjustPopUpViewSize; // (default is NO)

// by default the popUpView displays progress from 0% - 100%
// to display custom text instead, implement the datasource protocol - see below
// setting a dataSource automatically sets continuouslyAdjustPopUpViewSize to YES.
@property (weak, nonatomic) id<ASProgressPopUpViewDataSource> dataSource;

// delegate is only needed when used with a TableView or CollectionView - see below
@property (weak, nonatomic) id<ASProgressPopUpViewDelegate> delegate;
@end


// to supply custom text to the popUpView label, implement <ASProgressPopUpViewDataSource>
// the dataSource will be messaged each time the progress changes
@protocol ASProgressPopUpViewDataSource <NSObject>
- (NSString *)progressView:(ASProgressPopUpView *)progressView stringForProgress:(float)progress;

// required to calculate the default size for the popUpView
// must return an Array of all the custom strings which will be displayed
- (NSArray *)allStringsForProgressView:(ASProgressPopUpView *)progressView;
@end


// when embedding an ASProgressPopUpView inside a TableView or CollectionView
// you need to ensure that the cell it resides in is brought to the front of the view hierarchy
// to prevent the popUpView from being obscured
@protocol ASProgressPopUpViewDelegate <NSObject>
- (void)progressViewWillDisplayPopUpView:(ASProgressPopUpView *)progressView;

@optional
- (void)progressViewDidHidePopUpView:(ASProgressPopUpView *)progressView;
@end

/*
// the recommended technique for use with a tableView is to create a UITableViewCell subclass ↓
 
 @interface ProgressCell : UITableViewCell <ASProgressPopUpViewDelegate>
 @property (weak, nonatomic) IBOutlet ASProgressPopUpView *progressView;
 @end
 
 @implementation ProgressCell
 - (void)awakeFromNib
 {
    self.progressView.delegate = self;
 }
 
 - (void)progressViewWillDisplayPopUpView:(ASProgressPopUpView *)progressView;
 {
    [self.superview bringSubviewToFront:self];
 }
 @end
 */
