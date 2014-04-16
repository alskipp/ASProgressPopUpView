//
//  ViewController.m
//  Example
//
//  Created by Alan Skipp on 16/04/2014.
//  Copyright (c) 2014 Alan Skipp. All rights reserved.
//

#import "ViewController.h"
#import "ASProgressPopupView.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet ASProgressPopupView *progressView;
@property (weak, nonatomic) IBOutlet UIButton *progressButton;
@end

@implementation ViewController
{
    NSTimer *_timer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.progressView.font = [UIFont fontWithName:@"Futura-CondensedExtraBold" size:26];
    self.progressView.popUpViewAnimatedColors = @[[UIColor redColor], [UIColor orangeColor], [UIColor greenColor]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)startProgress:(UIButton *)sender
{
    sender.selected = !sender.selected;
    
    if (sender.selected) {
        if (self.progressView.progress >= 1.0) {
            self.progressView.progress = 0.0;
        }
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                                  target:self
                                                selector:@selector(increaseProgress:)
                                                userInfo:NULL repeats:YES];
    } else {
        [_timer invalidate];
    }

}

- (void)increaseProgress:(NSTimer *)timer
{
    self.progressView.progress += 0.01;
    if (self.progressView.progress >= 1.0) {
        [timer invalidate];
        self.progressButton.selected = NO;
    }
}

@end
