//
//  ViewController.m
//  Example
//
//  Created by Alan Skipp on 16/04/2014.
//  Copyright (c) 2014 Alan Skipp. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIButton *progressButton;
@end

@implementation ViewController
{
    NSTimer *_timer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    self.progressView.progress += 0.02;
    if (self.progressView.progress >= 1.0) {
        [timer invalidate];
        self.progressButton.selected = NO;
    }
}

@end
