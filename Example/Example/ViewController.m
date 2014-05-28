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
@property (weak, nonatomic) IBOutlet UIButton *continuousButton;
@end

@implementation ViewController
{
    NSTimer *_timer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.progressView1.font = [UIFont fontWithName:@"Futura-CondensedExtraBold" size:16];
    self.progressView1.popUpViewAnimatedColors = @[[UIColor redColor], [UIColor orangeColor], [UIColor greenColor]];
    self.progressView1.dataSource = self;
    
    self.progressView2.popUpViewCornerRadius = 12.0;
    self.progressView2.font = [UIFont fontWithName:@"Futura-CondensedExtraBold" size:28];
}

#pragma mark - IBActions

- (IBAction)toggleShowHide:(UISwitch *)sender
{
    if (sender.on) {
        [self.progressView1 showPopUpViewAnimated:YES];
        [self.progressView2 showPopUpViewAnimated:YES];
    } else {
        [self.progressView1 hidePopUpViewAnimated:YES];
        [self.progressView2 hidePopUpViewAnimated:YES];
    }
}

- (IBAction)toggleContinuousProgress:(UIButton *)sender
{
    sender.selected = !sender.selected;
}

- (IBAction)reset:(id)sender
{
    self.progressButton.selected = NO;
    self.progressButton.enabled = YES;
    
    self.progressView1.progress = 0.0;
    self.progressView2.progress = 0.0;
}

- (IBAction)startProgress:(UIButton *)sender
{
    sender.selected = !sender.selected;
    [self progress];
}

#pragma mark - Timer

- (void)progress
{
    if (self.progressView1.progress >= 1.0) {
        self.progressButton.selected = NO;
        self.progressButton.enabled = NO;
    }

    float progress = self.progressView1.progress;
    if (self.progressButton.selected && progress < 1.0) {
        
        progress += _continuousButton.selected ? 0.005 : 0.1;

        [self.progressView1 setProgress:progress animated:!_continuousButton.selected];
        [self.progressView2 setProgress:progress animated:!_continuousButton.selected];
        
        [NSTimer scheduledTimerWithTimeInterval:_continuousButton.selected ? 0.05 : 0.5
                                         target:self
                                       selector:@selector(progress)
                                       userInfo:nil
                                        repeats:NO];
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
