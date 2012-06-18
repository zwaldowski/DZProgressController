//
//  HudDemoViewController.m
//  DZProgressController Demo
//
//  (c) 2012 Zachary Waldowski.
//  (c) 2012 cocopon.
//  (c) 2009-2011 Matej Bukovinski and contributors.
//  This code is licensed under MIT. See LICENSE for more information. 
//

#import "HudDemoViewController.h"
#import "DZProgressController.h"

@implementation HudDemoViewController

#pragma mark - View controller

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;	
}

#pragma mark - Actions

- (IBAction)showSimple:(id)sender {
    // The hud will dispable all input on the view (use the higest view possible in the view hierarchy)
    DZProgressController *HUD = [DZProgressController new];
	
	// Show the HUD while the provided block executes in the background
	[HUD showWhileExecuting:^{
		sleep(3);
	}];
}

- (IBAction)showWithLabel:(id)sender {
    DZProgressController *HUD = [DZProgressController new];	
	HUD.label.text = @"Loading";
	[HUD showWhileExecuting:^{
		sleep(3);
	}];
}

- (IBAction)showWithLabelDeterminate:(id)sender {
    DZProgressController *HUD = [DZProgressController new];
	
    // Set determinate mode
    HUD.mode = DZProgressControllerModeDeterminate;
    HUD.label.text = @"Loading";
	
	// myProgressTask uses the HUD instance to update progress
	[HUD showWhileExecuting: ^{
		while (HUD.progress < 1.2f) {
			usleep(1000000);
			HUD.progress += 0.2f;
		}
	}];
}

- (IBAction)showWithLabelMixed:(id)sender {
    DZProgressController *HUD = [DZProgressController new];
	
    HUD.label.text = @"Connecting";
	
	[HUD showWhileExecuting: ^{
		// Indeterminate mode
		sleep(2);
		
		// Switch to determinate mode
		[HUD performChanges: ^{
			HUD.mode = DZProgressControllerModeDeterminate;
			HUD.label.text = @"Progress";
		}];
		
		CGFloat progress = 0.0f;
		while (progress < 1.04f)
		{
			progress += 0.01f;
			HUD.progress = progress;
			usleep(50000);
		}
		
		// Back to indeterminate mode
		[HUD performChanges: ^{
			HUD.mode = DZProgressControllerModeIndeterminate;
			HUD.label.text = @"Cleaning up";
		}];
		
		sleep(2);
		
		[HUD performChanges: ^{
			HUD.customView = DZProgressControllerSuccessView;
			HUD.mode = DZProgressControllerModeCustomView;
			HUD.label.text = @"Completed";
		}];
		
		sleep(2);
	}];
}

- (IBAction)showUsingBlocks:(id)sender {
	[DZProgressController showWithText:@"Loading" whileExecuting:^(DZProgressController *HUD){
		sleep(3);
	}];
}

- (IBAction)showURL:(id)sender {
	NSURL *URL = [NSURL URLWithString:@"https://github.com/zwaldowski/DZProgressHUD/zipball/master"];
	NSURLRequest *request = [NSURLRequest requestWithURL:URL];
	
	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	[connection start];
	
	networkHUD = [DZProgressController new];
	[networkHUD show];
}

- (IBAction)showWithSuccess:(id)sender {
	DZProgressController *HUD = [DZProgressController new];
	
	HUD.customView = DZProgressControllerSuccessView;
    HUD.mode = DZProgressControllerModeCustomView;
    HUD.label.text = @"Completed";
	
    [HUD show];
	[HUD hide];
}

- (IBAction)showWithError:(id)sender {
	DZProgressController *HUD = [DZProgressController new];
	
    HUD.mode = DZProgressControllerModeCustomView;
	HUD.customView = DZProgressControllerErrorView;
    HUD.label.text = @"Failed";
	
    [HUD show];
    [HUD hide];
}

#pragma mark - NSURLConnectionDelegete

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	expectedLength = [response expectedContentLength];
	currentLength = 0;
	networkHUD.mode = DZProgressControllerModeDeterminate;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	currentLength += [data length];
	networkHUD.progress = currentLength / (CGFloat)expectedLength;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[networkHUD performChanges:^{
		networkHUD.customView = DZProgressControllerSuccessView;
		networkHUD.mode = DZProgressControllerModeCustomView;
	}];
	[networkHUD hide];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[networkHUD performChanges:^{
		networkHUD.customView = DZProgressControllerErrorView;
		networkHUD.mode = DZProgressControllerModeCustomView;
	}];
	[networkHUD hide];
}

@end
