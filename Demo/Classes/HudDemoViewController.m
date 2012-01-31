//
//  HudDemoViewController.m
//  HudDemo
//
//  Created by Matej Bukovinski on 30.9.09.
//  Copyright bukovinski.com 2009. All rights reserved.
//

#import "HudDemoViewController.h"
#import <unistd.h>

@implementation HudDemoViewController

#pragma mark -
#pragma mark Constants

#pragma mark -
#pragma mark Lifecycle methods

- (void)viewDidLoad {
	UIView *content = [[self.view subviews] objectAtIndex:0];
	((UIScrollView *)self.view).contentSize = content.bounds.size;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;	
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	UIView *content = [[self.view subviews] objectAtIndex:0];
	((UIScrollView *)self.view).contentSize = content.bounds.size;
}

#pragma mark -
#pragma mark IBActions

- (IBAction)showSimple:(id)sender {
    // The hud will dispable all input on the view (use the higest view possible in the view hierarchy)
    HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:HUD];
	
    // Remote it from the window at the right time
	HUD.removeFromSuperViewOnHide = YES;
	
	// Show the HUD while the provided block executes in the background
	[HUD showWhileExecuting:^{
		[self myTask];
	}];
}

- (IBAction)showWithLabel:(id)sender {

    HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
	[self.navigationController.view addSubview:HUD];
	
	HUD.removeFromSuperViewOnHide = YES;
    HUD.labelText = @"Loading";
	
	[HUD showWhileExecuting:^{
		[self myTask];
	}];
}

- (IBAction)showWithDetailsLabel:(id)sender {
    HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:HUD];
	
	HUD.removeFromSuperViewOnHide = YES;
    HUD.labelText = @"Loading";
    HUD.detailsLabelText = @"updating data";
	
	[HUD showWhileExecuting:^{
		[self myTask];
	}];
}

- (IBAction)showWithLabelDeterminate:(id)sender {
    HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
	[self.navigationController.view addSubview:HUD];
	
    // Set determinate mode
    HUD.mode = MBProgressHUDModeDeterminate;
    
	HUD.removeFromSuperViewOnHide = YES;
    HUD.labelText = @"Loading";
	
	// myProgressTask uses the HUD instance to update progress
	[HUD showWhileExecuting:^{
		[self myProgressTask];
	}];
}

- (IBAction)showWithCustomView:(id)sender {

    HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
	[self.navigationController.view addSubview:HUD];
	
	// The sample image is based on the work by http://www.pixelpressicons.com, http://creativecommons.org/licenses/by/2.5/ca/
	// Make the customViews 37 by 37 pixels for best results (those are the bounds of the build-in progress indicators)
	HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
	
    // Set custom view mode
    HUD.mode = MBProgressHUDModeCustomView;
	
	HUD.removeFromSuperViewOnHide = YES;
    HUD.labelText = @"Completed";
	
    [HUD show:YES];
	[HUD hide:YES afterDelay:3];
}

- (IBAction)showWithLabelMixed:(id)sender {
    HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
	[self.navigationController.view addSubview:HUD];
	
	HUD.removeFromSuperViewOnHide = YES;
    HUD.labelText = @"Connecting";
	HUD.minSize = CGSizeMake(135.f, 135.f);
	
	[HUD showWhileExecuting:^{
		[self myMixedTask];
	}];
}

- (IBAction)showUsingBlocks:(id)sender {
	MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
	[self.navigationController.view addSubview:hud];
	hud.labelText = @"Loading";
	hud.removeFromSuperViewOnHide = YES;
	[hud showWhileExecuting:^{
		[self myTask];
	}];
}

- (IBAction)showOnWindow:(id)sender {
	// The hud will dispable all input on the window
    HUD = [[MBProgressHUD alloc] initWithView:self.view.window];
    [self.view.window addSubview:HUD];
	
	HUD.removeFromSuperViewOnHide = YES;
    HUD.labelText = @"Loading";
	
	[HUD showWhileExecuting:^{
		[self myTask];
	}];
}

- (IBAction)showURL:(id)sender {
	NSURL *URL = [NSURL URLWithString:@"https://github.com/matej/MBProgressHUD/zipball/master"];
	NSURLRequest *request = [NSURLRequest requestWithURL:URL];
	
	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	[connection start];
	
	HUD = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
}


- (IBAction)showWithGradient:(id)sender {
    HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
	[self.navigationController.view addSubview:HUD];
	
	// Regiser for HUD callbacks so we can remove it from the window at the right time
	HUD.removeFromSuperViewOnHide = YES;
	
    // Show the HUD while the provided block executes in the background
	[HUD showWhileExecuting:^{
		[self myTask];
	}];
}

#pragma mark -
#pragma mark Execution code

- (void)myTask {
    // Do something usefull in here instead of sleeping ...
    sleep(3);
}

- (void)myProgressTask {
    // This just increases the progress indicator in a loop
    CGFloat progress = 0.0f;
    while (progress < 1.0f) {
        progress += 0.01f;
        HUD.progress = progress;
        usleep(50000);
    }
}

- (void)myMixedTask {
    // Indeterminate mode
    sleep(2);
    // Switch to determinate mode
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.labelText = @"Progress";
    CGFloat progress = 0.0f;
    while (progress < 1.0f)
    {
        progress += 0.01f;
        HUD.progress = progress;
        usleep(50000);
    }
    // Back to indeterminate mode
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.labelText = @"Cleaning up";
    sleep(2);
	// The sample image is based on the work by www.pixelpressicons.com, http://creativecommons.org/licenses/by/2.5/ca/
	// Make the customViews 37 by 37 pixels for best results (those are the bounds of the build-in progress indicators)
	HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
	HUD.mode = MBProgressHUDModeCustomView;
	HUD.labelText = @"Completed";
	sleep(2);
}

#pragma mark -
#pragma mark NSURLConnectionDelegete

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	expectedLength = [response expectedContentLength];
	currentLength = 0;
	HUD.mode = MBProgressHUDModeDeterminate;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	currentLength += [data length];
	HUD.progress = currentLength / (float)expectedLength;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
    HUD.mode = MBProgressHUDModeCustomView;
	[HUD hide:YES afterDelay:2];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[HUD hide:YES];
}

@end
