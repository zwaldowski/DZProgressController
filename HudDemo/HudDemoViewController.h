//
//  HudDemoViewController.h
//  HudDemo
//
//  Created by Matej Bukovinski on 30.9.09.
//  Copyright bukovinski.com 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MBProgressHUD;

@interface HudDemoViewController : UIViewController {
	MBProgressHUD *networkHUD;
	
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

