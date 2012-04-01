//
//  HudDemoViewController.m
//  HudDemo
//
//  (c) 2012 Zachary Waldowski.
//  (c) 2009-2011 Matej Bukovinski and contributors.
//  This code is licensed under MIT. See LICENSE for more information. 
//

#import "HudDemoViewController.h"
#import "DZProgressHUD.h"

@implementation HudDemoViewController

#pragma mark - View controller

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;	
}

#pragma mark - Actions

- (IBAction)showSimple:(id)sender {
    // The hud will dispable all input on the view (use the higest view possible in the view hierarchy)
    DZProgressHUD *HUD = [DZProgressHUD new];
	
	// Show the HUD while the provided block executes in the background
	[HUD showWhileExecuting:^{
		sleep(3);
	}];
}

- (IBAction)showWithLabel:(id)sender {
    DZProgressHUD *HUD = [DZProgressHUD new];	
	HUD.label.text = @"Loading";
	[HUD showWhileExecuting:^{
		sleep(3);
	}];
}

- (IBAction)showWithLabelDeterminate:(id)sender {
    DZProgressHUD *HUD = [DZProgressHUD new];
	
    // Set determinate mode
    HUD.mode = DZProgressHUDModeDeterminate;
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
    DZProgressHUD *HUD = [DZProgressHUD new];
	
    HUD.label.text = @"Connecting";
	
	[HUD showWhileExecuting: ^{
		// Indeterminate mode
		sleep(2);
		
		// Switch to determinate mode
		[HUD performChanges: ^{
			HUD.mode = DZProgressHUDModeDeterminate;
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
			HUD.mode = DZProgressHUDModeIndeterminate;
			HUD.label.text = @"Cleaning up";
		}];
		
		sleep(2);
		
		[HUD performChanges: ^{
			HUD.customView = DZProgressHUDSuccessImageView;
			HUD.mode = DZProgressHUDModeCustomView;
			HUD.label.text = @"Completed";
		}];
		
		sleep(2);
	}];
}

- (IBAction)showUsingBlocks:(id)sender {
	[DZProgressHUD showWithText:@"Loading" whileExecuting:^(DZProgressHUD *HUD){
		sleep(3);
	}];
}

- (IBAction)showURL:(id)sender {
	NSURL *URL = [NSURL URLWithString:@"https://github.com/matej/DZProgressHUD/zipball/master"];
	NSURLRequest *request = [NSURLRequest requestWithURL:URL];
	
	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	[connection start];
	
	networkHUD = [DZProgressHUD new];
	[networkHUD show];
}

- (IBAction)showWithSuccess:(id)sender {
	DZProgressHUD *HUD = [DZProgressHUD new];
	
	HUD.customView = DZProgressHUDSuccessImageView;
    HUD.mode = DZProgressHUDModeCustomView;
    HUD.label.text = @"Completed";
	
    [HUD show];
	[HUD hide];
}

- (IBAction)showWithError:(id)sender {
	DZProgressHUD *HUD = [DZProgressHUD new];
	
    HUD.mode = DZProgressHUDModeCustomView;
	HUD.customView = DZProgressHUDErrorImageView;
    HUD.label.text = @"Failed";
	
    [HUD show];
    [HUD hide];
}

#pragma mark - NSURLConnectionDelegete

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	expectedLength = [response expectedContentLength];
	currentLength = 0;
	[networkHUD performChanges:^{
		networkHUD.mode = DZProgressHUDModeDeterminate;
	}];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	currentLength += [data length];
	[networkHUD setProgress:currentLength / (CGFloat)expectedLength animated:YES];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[networkHUD performChanges:^{
		networkHUD.customView = DZProgressHUDSuccessImageView;
		networkHUD.mode = DZProgressHUDModeCustomView;
	}];
	[networkHUD hide];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[networkHUD performChanges:^{
		networkHUD.customView = DZProgressHUDErrorImageView;
		networkHUD.mode = DZProgressHUDModeCustomView;
	}];
	[networkHUD hide];
}

@end
