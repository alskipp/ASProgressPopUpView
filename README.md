ASProgressPopUpView
========

###What is it?


A UIProgressView subclass that displays the percentage complete in an easy to customize popup view. It’s the cousin to [ASValueTrackingSlider](https://github.com/alskipp/ASValueTrackingSlider).

![screenshot] (http://alskipp.github.io/ASProgressPopUpView/img/screenshot1.gif)

Features
---

* Live updating of progress
* Customizable properties:
  * textColor
  * font
  * popUpViewColor
  * popUpViewAnimatedColors - popUpView and progress bar color animate as value changes
* Wholesome springy animation


Which files are needed?
---

For [CocoaPods](http://beta.cocoapods.org) users, simply add `pod 'ASProgressPopupView'` to your podfile. Don't forget, CocoaPods includes the `try` command, type `$ pod try ASProgressPopupView` in the terminal, CocoaPods will download the demo project into a temp folder and open it in Xcode. Magic.

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
```

You update the value exactly as you would normally use a UIProgressView, just update the ‘progress’ property `self.progressView.progress = 0.5;`.

![screenshot] (http://alskipp.github.io/ASProgressPopUpView/img/screenshot2.png)

###How to use with UITableView

To use  effectively inside a UITableView you need to implement the `<ASProgressPopUpViewDelegate>` protocol. If you just embed an ASProgressPopUpView inside a UITableViewCell the popUpView will probably be obscured by the cell above. The delegate method notifies you before the popUpView appears so that you can ensure that your UITableViewCell is rendered above the others.

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
 
