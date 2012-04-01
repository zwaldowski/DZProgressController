//
//  HudDemoViewController.h
//  HudDemo
//
//  (c) 2012 Zachary Waldowski.
//  (c) 2009-2011 Matej Bukovinski and contributors.
//  This code is licensed under MIT. See LICENSE for more information. 
//

#import <UIKit/UIKit.h>

@class DZProgressHUD;

@interface HudDemoViewController : UIViewController {
	DZProgressHUD *networkHUD;
	
	long long expectedLength;
	long long currentLength;
}

- (IBAction)showSimple:(id)sender;
- (IBAction)showWithLabel:(id)sender;
- (IBAction)showWithLabelDeterminate:(id)sender;
- (IBAction)showWithLabelMixed:(id)sender;
- (IBAction)showUsingBlocks:(id)sender;
- (IBAction)showURL:(id)sender;
- (IBAction)showWithSuccess:(id)sender;
- (IBAction)showWithError:(id)sender;

@end

