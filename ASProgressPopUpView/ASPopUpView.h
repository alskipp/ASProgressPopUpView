//
//  ASPopUpView.h
//  ASProgressPopUpView
//
//  Created by Alan Skipp on 16/04/2013.
//  Copyright (c) 2014 Alan Skipp. All rights reserved.
//

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// This UIView subclass is used internally by ASProgressPopUpView
// The public API is declared in ASProgressPopUpView.h
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#import <UIKit/UIKit.h>

@protocol ASPopUpViewDelegate <NSObject>
- (CGFloat)currentValueOffset; //expects value in the range 0.0 - 1.0
- (void)colorDidUpdate;
- (void)popUpViewDidHide;
@end

@interface ASPopUpView : UIView

@property (weak, nonatomic) id <ASPopUpViewDelegate> delegate;
@property (nonatomic) CGFloat cornerRadius;

- (UIColor *)color;
- (void)setColor:(UIColor *)color;
- (UIColor *)opaqueColor;

- (void)setTextColor:(UIColor *)textColor;
- (void)setFont:(UIFont *)font;
- (void)setText:(NSString *)text;

- (void)setAnimatedColors:(NSArray *)animatedColors withKeyTimes:(NSArray *)keyTimes;

// sets the specified view properties immediately without animation
- (void)setFrame:(CGRect)frame
     arrowOffset:(CGFloat)arrowOffset
           text:(NSString *)text
 animationOffset:(CGFloat)animOffset;

// animates the specified view properties from current state to new state with the given duration
- (void)animateFrame:(CGRect)frame
         arrowOffset:(CGFloat)arrowOffset
                text:(NSString *)text
     animationOffset:(CGFloat)animOffset
            duration:(NSTimeInterval)duration
          completion:(void (^)(UIColor *endColor))completion;

- (CGSize)popUpSizeForString:(NSString *)string;

- (void)show;
- (void)hide;

@end