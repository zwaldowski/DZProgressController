//
//  HudDemoViewController.m
//  HudDemo
//
//  Created by Matej Bukovinski on 30.9.09.
//  Copyright bukovinski.com 2009. All rights reserved.
//

#import "HudDemoViewController.h"
#import "MBProgressHUD.h"

@implementation HudDemoViewController

#pragma mark - View controller

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;	
}

#pragma mark - Actions

- (IBAction)showSimple:(id)sender {
    // The hud will dispable all input on the view (use the higest view possible in the view hierarchy)
    MBProgressHUD *HUD = [MBProgressHUD new];
	
	// Show the HUD while the provided block executes in the background
	[HUD showWhileExecuting:^{
		sleep(3);
	}];
}

- (IBAction)showWithLabel:(id)sender {
    MBProgressHUD *HUD = [MBProgressHUD new];	
	HUD.label.text = @"Loading";
	[HUD showWhileExecuting:^{
		sleep(3);
	}];
}

- (IBAction)showWithLabelDeterminate:(id)sender {
    MBProgressHUD *HUD = [MBProgressHUD new];
	
    // Set determinate mode
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.label.text = @"Loading";
	
	// myProgressTask uses the HUD instance to update progress
	[HUD showWhileExecuting: ^{
		HUD.progress = 0.0f;
		while (HUD.progress < 1.0f) {
			usleep(1000000);
			HUD.progress += 0.2f;
		}
	}];
}

- (IBAction)showWithLabelMixed:(id)sender {
    MBProgressHUD *HUD = [MBProgressHUD new];
	
    HUD.label.text = @"Connecting";
	
	[HUD showWhileExecuting: ^{
		// Indeterminate mode
		sleep(2);
		
		// Switch to determinate mode
		[HUD performChanges: ^{
			HUD.mode = MBProgressHUDModeDeterminate;
			HUD.label.text = @"Progress";
		}];
		
		CGFloat progress = 0.0f;
		while (progress < 1.0f)
		{
			progress += 0.01f;
			HUD.progress = progress;
			usleep(50000);
		}
		
		// Back to indeterminate mode
		[HUD performChanges: ^{
			HUD.mode = MBProgressHUDModeIndeterminate;
			HUD.label.text = @"Cleaning up";
		}];
		
		sleep(2);
		
		[HUD performChanges: ^{
			HUD.customView = MBProgressHUDSuccessImageView;
			HUD.mode = MBProgressHUDModeCustomView;
			HUD.label.text = @"Completed";
		}];
		
		sleep(2);
	}];
}

- (IBAction)showUsingBlocks:(id)sender {
	[MBProgressHUD showWithText:@"Loading" whileExecuting:^(MBProgressHUD *HUD){
		sleep(3);
	}];
}

- (IBAction)showURL:(id)sender {
	NSURL *URL = [NSURL URLWithString:@"https://github.com/matej/MBProgressHUD/zipball/master"];
	NSURLRequest *request = [NSURLRequest requestWithURL:URL];
	
	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	[connection start];
	
	networkHUD = [MBProgressHUD new];
	[networkHUD show];
}

- (IBAction)showWithSuccess:(id)sender {
	MBProgressHUD *HUD = [MBProgressHUD new];
	
	HUD.customView = MBProgressHUDSuccessImageView;
    HUD.mode = MBProgressHUDModeCustomView;
    HUD.label.text = @"Completed";
	
    [HUD show];
	[HUD hide];
}

- (IBAction)showWithError:(id)sender {
	MBProgressHUD *HUD = [MBProgressHUD new];
	
    HUD.mode = MBProgressHUDModeCustomView;
	HUD.customView = MBProgressHUDErrorImageView;
    HUD.label.text = @"Failed";
	
    [HUD show];
    [HUD hide];
}

#pragma mark - NSURLConnectionDelegete

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	expectedLength = [response expectedContentLength];
	currentLength = 0;
	[networkHUD performChanges:^{
		networkHUD.mode = MBProgressHUDModeDeterminate;
	}];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	currentLength += [data length];
	networkHUD.progress = currentLength / (CGFloat)expectedLength;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[networkHUD performChanges:^{
		networkHUD.customView = MBProgressHUDSuccessImageView;
		networkHUD.mode = MBProgressHUDModeCustomView;
	}];
	[networkHUD hide];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[networkHUD performChanges:^{
		networkHUD.customView = MBProgressHUDErrorImageView;
		networkHUD.mode = MBProgressHUDModeCustomView;
	}];
	[networkHUD hide];
}

@end
