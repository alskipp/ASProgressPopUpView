//
//  ViewController.m
//  Example
//
//  Created by Alan Skipp on 16/04/2014.
//  Copyright (c) 2014 Alan Skipp. All rights reserved.
//

#import "ViewController.h"
#import "ASProgressPopUpView.h"

@interface ViewController () <ASProgressPopUpViewDataSource>
@property (weak, nonatomic) IBOutlet ASProgressPopUpView *progressView1;
@property (weak, nonatomic) IBOutlet ASProgressPopUpView *progressView2;
@property (weak, nonatomic) IBOutlet UIButton *progressButton;
@end

@implementation ViewController
{
    NSTimer *_timer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.progressView1.font = [UIFont fontWithName:@"Futura-CondensedExtraBold" size:26];
    self.progressView1.popUpViewAnimatedColors = @[[UIColor redColor], [UIColor orangeColor], [UIColor greenColor]];
    self.progressView1.dataSource = self;
}

#pragma mark - IBActions

- (IBAction)startProgress:(UIButton *)sender
{
    sender.selected = !sender.selected;
    
    if (sender.selected) {
        if (self.progressView1.progress >= 1.0) {
            self.progressView1.progress = 0.0;
            self.progressView2.progress = 0.0;
        }
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                                  target:self
                                                selector:@selector(increaseProgress:)
                                                userInfo:NULL repeats:YES];
    } else {
        [_timer invalidate];
    }
}

- (IBAction)toggleShowHide:(UISwitch *)sender
{
    self.progressView1.alwaysShowPopUpView = sender.on ?: NO;
    self.progressView2.alwaysShowPopUpView = sender.on ?: NO;
}

#pragma mark - Timer

- (void)increaseProgress:(NSTimer *)timer
{
    self.progressView1.progress += 0.01;
    self.progressView2.progress += 0.01;
    if (self.progressView1.progress >= 1.0) {
        [timer invalidate];
        self.progressButton.selected = NO;
    }
}

#pragma mark - ASProgressPopUpView dataSource

// <ASProgressPopUpViewDataSource> is entirely optional
// it allows you to supply custom NSStrings to ASProgressPopUpView
- (NSString *)progressView:(ASProgressPopUpView *)progressView stringForProgress:(float)progress
{
    NSString *s;
    if (progress < 0.2) {
        s = @"Just starting";
    } else if (progress > 0.4 && progress < 0.6) {
        s = @"About halfway";
    } else if (progress > 0.75 && progress < 1.0) {
        s = @"Nearly there";
    } else if (progress >= 1.0) {
        s = @"Complete";
    }
    return s;
}

// by default ASProgressPopUpView precalculates the largest popUpView size needed
// it then uses this size for all values and maintains a consistent size
// if you want the popUpView size to adapt as values change then return 'NO'
- (BOOL)progressViewShouldPreCalculatePopUpViewSize:(ASProgressPopUpView *)progressView;
{
    return NO;
}

#pragma mark - Cleanup

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
