ASProgressPopUpView
========

###What is it?


A UIProgressView subclass that displays the percentage complete in an easy to customize popUpView.

![screenshot] (http://alskipp.github.io/ASProgressPopUpView/img/screenshot1.gif)

If you'd like similar functionality for UISlider, then take a look at [ASValueTrackingSlider](https://github.com/alskipp/ASValueTrackingSlider).


Features
---

* Live updating of progress
* Customizable properties:
  * textColor
  * font
  * popUpViewColor
  * popUpViewAnimatedColors - popUpView and progress bar color animate as value changes
  * popUpViewCornerRadius
* Optional dataSource - supply your own custom text to the popUpView label
* Wholesome springy animation


Which files are needed?
---

For [CocoaPods](http://beta.cocoapods.org) users, simply add `pod 'ASProgressPopUpView'` to your podfile. Don't forget, CocoaPods includes the `try` command, type `$ pod try ASProgressPopUpView` in the terminal, CocoaPods will download the demo project into a temp folder and open it in Xcode. Magic.

If you don't use CocoaPods, just include these files in your project:

* ASProgressPopUpView (.h .m)
* ASPopUpView (.h .m)


How to use it
---

It’s very simple. Drag a UIProgressView into your Storyboard/nib and set its class to ASProgressPopUpView – that's it.
The example below demonstrates how to customize the appearance.

```objective-c
self.progressView.font = [UIFont fontWithName:@"Futura-CondensedExtraBold" size:26];
self.progressView.popUpViewAnimatedColors = @[[UIColor redColor], [UIColor orangeColor], [UIColor greenColor]];
self.progressView.popUpViewCornerRadius = 16.0;
```

You update the value exactly as you would normally use a UIProgressView, just update the `progress` property `self.progressView.progress = 0.31;`.

![screenshot] (http://alskipp.github.io/ASProgressPopUpView/img/screenshot2.png)

With `version 0.7.1` and above, the animated progress method is supported `- (void)setProgress:(float)progress animated:(BOOL)animated`. When updating the progress in increments `> 0.05` the results will be much smoother using the animated form.


###How to use custom strings in popUpView label

Set your controller as the `dataSource` to `ASProgressPopUpView`, then return NSStrings for any progress values you want to customize.
  
```objective-c
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
```

![screenshot] (http://alskipp.github.io/ASProgressPopUpView/img/screenshot3.png)


###How to use with UITableView

To use effectively inside a UITableView you need to implement the `<ASProgressPopUpViewDelegate>` protocol. If you just embed an ASProgressPopUpView inside a UITableViewCell the popUpView will probably be obscured by the cell above. The delegate method notifies you before the popUpView appears so that you can ensure that your UITableViewCell is rendered above the others.

The recommended technique for use with UITableView is to create a UITableViewCell subclass that implements the delegate method.


```objective-c
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
```
 
