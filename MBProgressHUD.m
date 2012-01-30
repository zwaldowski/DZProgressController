//
//  MBProgressHUD.m
//  Version 0.4
//  Created by Matej Bukovinski on 2.4.09.
//
// This code is licensed under MIT. See LICENSE for more information. 
//

#import "MBProgressHUD.h"

// A progress view for showing definite progress by filling up a circle (pie chart).
@interface MBRoundProgressView : UIView
@property (nonatomic) CGFloat progress;
@end

@interface MBProgressHUD () {
	UIStatusBarStyle oldStatusBarStyle;
	BOOL useAnimation;
}

- (void)updateLabelText:(NSString *)newText;
- (void)updateDetailsLabelText:(NSString *)newText;
- (void)updateProgress;
- (void)updateIndicators;
- (void)setTransformForCurrentOrientation:(BOOL)animated;
- (void)deviceOrientationDidChange:(NSNotification *)notification;

@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UILabel *detailsLabel;

@property (nonatomic, strong) UIView *indicator;
@property (nonatomic, strong) NSDate *showStarted;

@property (nonatomic) CGSize HUDSize;

@end


@implementation MBProgressHUD

#pragma mark -
#pragma mark Accessors


@synthesize mode;
@synthesize animationType;

@synthesize delegate;

@synthesize label, detailsLabel;
@synthesize labelText, detailsLabelText;
@synthesize labelFont, detailsLabelFont;

@synthesize opacity;

@synthesize indicator;

@synthesize HUDSize;
@synthesize xOffset;
@synthesize yOffset;
@synthesize minSize;
@synthesize margin;
@synthesize dimBackground;

@synthesize graceTime;
@synthesize minShowTime;
@synthesize taskInProgress;
@synthesize removeFromSuperViewOnHide;

@synthesize progress;

@synthesize customView;

@synthesize showStarted;

- (void)setMode:(MBProgressHUDMode)newMode {
    // Dont change mode if it wasn't actually changed to prevent flickering
    if (mode && (mode == newMode)) {
        return;
    }
	
    mode = newMode;
	
	if ([NSThread isMainThread]) {
		[self updateIndicators];
		[self setNeedsLayout];
		[self setNeedsDisplay];
	} else {
		[self performSelectorOnMainThread:@selector(updateIndicators) withObject:nil waitUntilDone:NO];
		[self performSelectorOnMainThread:@selector(setNeedsLayout) withObject:nil waitUntilDone:NO];
		[self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
	}
}

- (void)setLabelText:(NSString *)newText {
	if ([NSThread isMainThread]) {
		[self updateLabelText:newText];
		[self setNeedsLayout];
		[self setNeedsDisplay];
	} else {
		[self performSelectorOnMainThread:@selector(updateLabelText:) withObject:newText waitUntilDone:NO];
		[self performSelectorOnMainThread:@selector(setNeedsLayout) withObject:nil waitUntilDone:NO];
		[self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
	}
}

- (void)setDetailsLabelText:(NSString *)newText {
	if ([NSThread isMainThread]) {
		[self updateDetailsLabelText:newText];
		[self setNeedsLayout];
		[self setNeedsDisplay];
	} else {
		[self performSelectorOnMainThread:@selector(updateDetailsLabelText:) withObject:newText waitUntilDone:NO];
		[self performSelectorOnMainThread:@selector(setNeedsLayout) withObject:nil waitUntilDone:NO];
		[self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
	}
}

- (void)setProgress:(float)newProgress {
    progress = newProgress;
	
    // Update display ony if showing the determinate progress view
    if (mode != MBProgressHUDModeDeterminate)
		return;
	
	if ([NSThread isMainThread]) {
		[self updateProgress];
	} else {
		[self performSelectorOnMainThread:@selector(updateProgress) withObject:nil waitUntilDone:NO];
	}
}

#pragma mark -
#pragma mark Accessor helpers

- (void)updateLabelText:(NSString *)newText {
    if (labelText != newText) {
        labelText = [newText copy];
    }
}

- (void)updateDetailsLabelText:(NSString *)newText {
    if (detailsLabelText != newText) {
        detailsLabelText = [newText copy];
    }
}

- (void)updateProgress {
	if (![indicator isKindOfClass:[MBRoundProgressView class]])
		return;
	[(MBRoundProgressView *)indicator setProgress:progress];
}

- (void)updateIndicators {
    if (indicator) {
        [indicator removeFromSuperview];
    }
	
    if (mode == MBProgressHUDModeDeterminate) {
        self.indicator = [MBRoundProgressView new];
	} else if (mode == MBProgressHUDModeCustomView && self.customView) {
        self.indicator = self.customView;
    } else {
		UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		[view startAnimating];
		self.indicator = view;
	}

    [self addSubview:indicator];
}

#pragma mark -
#pragma mark Constants

#define PADDING 4.0f

#define LABELFONTSIZE 16.0f
#define LABELDETAILSFONTSIZE 12.0f

#pragma mark -
#pragma mark Class methods

+ (MBProgressHUD *)showHUDAddedTo:(UIView *)view animated:(BOOL)animated {
	MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:view];
	[view addSubview:hud];
	[hud show:animated];
	return hud;
}

+ (BOOL)hideHUDForView:(UIView *)view animated:(BOOL)animated {
	UIView *viewToRemove = nil;
	for (UIView *v in [view subviews]) {
		if ([v isKindOfClass:[MBProgressHUD class]]) {
			viewToRemove = v;
		}
	}
	if (viewToRemove != nil) {
		MBProgressHUD *HUD = (MBProgressHUD *)viewToRemove;
		HUD.removeFromSuperViewOnHide = YES;
		[HUD hide:animated];
		return YES;
	} else {
		return NO;
	}
}


#pragma mark -
#pragma mark Lifecycle methods

- (id)initWithWindow:(UIWindow *)window {
    return [self initWithView:window];
}

- (id)initWithView:(UIView *)view {
	// Let's check if the view is nil (this is a common error when using the windw initializer above)
	if (!view) {
		[NSException raise:@"MBProgressHUDViewIsNillException" 
					format:@"The view used in the MBProgressHUD initializer is nil."];
	}
	id me = [self initWithFrame:view.bounds];
	// We need to take care of rotation ourselfs if we're adding the HUD to a window
	if ([view isKindOfClass:[UIWindow class]]) {
		[self setTransformForCurrentOrientation:NO];
	}
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) 
												 name:UIDeviceOrientationDidChangeNotification object:nil];
	
	return me;
}

- (void)removeFromSuperview {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceOrientationDidChangeNotification
                                                  object:nil];
    
    [super removeFromSuperview];
}


- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
	if (self) {
        // Set default values for properties
        self.animationType = MBProgressHUDAnimationFade;
        self.mode = MBProgressHUDModeIndeterminate;
        self.labelText = nil;
        self.detailsLabelText = nil;
        self.opacity = 0.8f;
        self.labelFont = [UIFont boldSystemFontOfSize:LABELFONTSIZE];
        self.detailsLabelFont = [UIFont boldSystemFontOfSize:LABELDETAILSFONTSIZE];
        self.xOffset = 0.0f;
        self.yOffset = 0.0f;
		self.dimBackground = NO;
		self.margin = 20.0f;
		self.graceTime = 0.0f;
		self.minShowTime = 0.0f;
		self.removeFromSuperViewOnHide = NO;
		self.minSize = CGSizeZero;
		
		self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		
        // Transparent background
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
		
        // Make invisible for now
        self.alpha = 0.0f;
		
        // Add label
        self.label = [[UILabel alloc] initWithFrame:self.bounds];
		
        // Add details label
        self.detailsLabel = [[UILabel alloc] initWithFrame:self.bounds];
		
		taskInProgress = NO;
    }
    return self;
}

#pragma mark -
#pragma mark Layout

- (void)layoutSubviews {
	CGRect frame = self.bounds, lFrame = CGRectZero, dFrame = CGRectZero, indFrame = indicator.bounds;
	CGSize newSize = CGSizeMake(indFrame.size.width + 2 * margin, indFrame.size.height + 2 * margin);
	
	indFrame.origin.x = floorf((frame.size.width - indFrame.size.width) / 2) + self.xOffset;
    indFrame.origin.y = floorf((frame.size.height - indFrame.size.height) / 2) + self.yOffset;
	
    // Add label if label text was set
    if (self.labelText) {		
        // Set label properties
        self.label.font = self.labelFont;
        self.label.adjustsFontSizeToFitWidth = NO;
        self.label.textAlignment = UITextAlignmentCenter;
        self.label.opaque = NO;
        self.label.backgroundColor = [UIColor clearColor];
        self.label.textColor = [UIColor whiteColor];
        self.label.text = self.labelText;
		
		// Compute label dimensions based on font metrics if size is larger than max then clip the label width
		CGSize maxSize = CGSizeMake(frame.size.width - 4 * margin, frame.size.height - newSize.height - 2 * margin);
        CGSize dims = [self.labelText sizeWithFont:self.labelFont constrainedToSize:maxSize lineBreakMode:UILineBreakModeClip];
		
        // Update HUD size
		if (newSize.width < dims.width + 2 * margin)
            newSize.width = dims.width + 2 * margin;
        newSize.height += dims.height + PADDING;
		
        // Set the label position and dimensions
		lFrame.origin.x = floor((frame.size.width - dims.width) / 2);
		lFrame.origin.y = CGRectGetMaxY(indFrame) - PADDING;
		lFrame.size = dims;
		
        // Move indicator to make room for the label
        indFrame.origin.y -= floor(dims.height / 2) + PADDING;
		
        [self addSubview:label];
    }
	
	// Add details label delatils text was set
	if (self.detailsLabelText) {
		
		// Set label properties
		self.detailsLabel.font = self.detailsLabelFont;
		self.detailsLabel.adjustsFontSizeToFitWidth = NO;
		self.detailsLabel.textAlignment = UITextAlignmentCenter;
		self.detailsLabel.opaque = NO;
		self.detailsLabel.backgroundColor = [UIColor clearColor];
		self.detailsLabel.textColor = [UIColor whiteColor];
		self.detailsLabel.text = self.detailsLabelText;
		self.detailsLabel.numberOfLines = 0;
		
		CGSize maxSize = CGSizeMake(frame.size.width - 4 * margin, frame.size.height - newSize.height - 2*margin);
		CGSize dims = [self.detailsLabelText sizeWithFont:self.detailsLabelFont constrainedToSize:maxSize lineBreakMode:self.detailsLabel.lineBreakMode];
		
		// Update HUD size
		if (newSize.width < dims.width + 2 * margin)
			newSize.width = dims.width + 2 * margin;
		newSize.height += dims.height + PADDING;
		
		// Move indicator to make room for the new label
		indFrame.origin.y -= (floor(dims.height / 2 + PADDING / 2));
		
		// Move first label to make room for the new label
		lFrame.origin.y -= (floor(dims.height / 2 + PADDING / 2));
		
		// Set label position and dimensions
		dFrame.origin.x = floor((frame.size.width - dims.width) / 2);
		dFrame.origin.y = CGRectGetMaxY(lFrame) + PADDING * 2;
		dFrame.size = dims;
		
		[self addSubview:self.detailsLabel];
	}
	
	label.frame = lFrame;
	detailsLabel.frame = dFrame;
	indicator.frame = indFrame;
	
	if (newSize.width < minSize.width) {
		newSize.width = minSize.width;
	} 
	
	if (newSize.height < minSize.height) {
		newSize.height = minSize.height;
	}
	
	self.HUDSize = newSize;
}

#pragma mark -
#pragma mark Showing and execution

- (void)show:(BOOL)animated {
	NSTimeInterval length = animated ? (1./3.) : 0;
	NSTimeInterval graceTimeDelay = self.graceTime;
	self.alpha = 0.0f;
	
	if (dimBackground) {
		oldStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];

		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, graceTimeDelay * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^{
			[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
		});
	}
	
	[UIView animateWithDuration:length delay:graceTimeDelay options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
		if (animationType == MBProgressHUDAnimationZoom) {
			self.transform = CGAffineTransformConcat(self.transform, CGAffineTransformMakeScale(1.5f, 1.5f));
		}
		self.alpha = 1.0f;
	} completion:^(BOOL finished) {
		self.showStarted = [NSDate date];
	}];
}

- (void)hide:(BOOL)animated {
	[self hide:animated afterDelay:0.0];
}

- (void)hide:(BOOL)animated afterDelay:(NSTimeInterval)delay {
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^{
		NSTimeInterval length = animated ? (1./3.) : 0;
		NSTimeInterval minimumShowDelay = 0.0;
		if (showStarted)
			minimumShowDelay = self.minShowTime - [[NSDate date] timeIntervalSinceDate:showStarted];
		
		if (dimBackground)
			[[UIApplication sharedApplication] setStatusBarStyle:oldStatusBarStyle animated:YES];
		
		[UIView animateWithDuration:length delay:minimumShowDelay options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
			if (animationType == MBProgressHUDAnimationZoom)
				self.transform = CGAffineTransformConcat(self.transform, CGAffineTransformMakeScale(0.5f, 0.5f));
			self.alpha = 0.0f;
		} completion:^(BOOL finished) {
			if ([delegate respondsToSelector:@selector(HUDWasHidden:)])
				[delegate HUDWasHidden:self];
			
			if (removeFromSuperViewOnHide)
				[self removeFromSuperview];
		}];
	});
}

- (void)showWhileExecuting:(dispatch_block_t)block {
	if (!block) return;
	
	dispatch_queue_t bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(bgQueue, ^{
		self.taskInProgress = YES;
		
		dispatch_sync(dispatch_get_main_queue(), ^{
			[self show:YES];
		});
		
		@autoreleasepool {
			block();
		}
		
		self.taskInProgress = NO;
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if (self.superview)
				[self hide:YES];
		});
	});
}

#pragma mark BG Drawing

- (void)drawRect:(CGRect)rect {
	
    CGContextRef context = UIGraphicsGetCurrentContext();

    if (dimBackground) {
        //Gradient colours
        size_t gradLocationsNum = 2;
        CGFloat gradLocations[2] = {0.0f, 1.0f};
        CGFloat gradColors[8] = {0.0f,0.0f,0.0f,0.0f,0.0f,0.0f,0.0f,0.75f}; 
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, gradColors, gradLocations, gradLocationsNum);
		CGColorSpaceRelease(colorSpace);
        
        //Gradient center
        CGPoint gradCenter= CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        //Gradient radius
        float gradRadius = MIN(self.bounds.size.width , self.bounds.size.height) ;
        //Gradient draw
        CGContextDrawRadialGradient (context, gradient, gradCenter,
                                     0, gradCenter, gradRadius,
                                     kCGGradientDrawsAfterEndLocation);
		CGGradientRelease(gradient);
    }    
    
    // Draw rounded HUD background rect
	CGRect boxRect = CGRectZero;
	boxRect.size = self.HUDSize;
	boxRect.origin.x = roundf((self.bounds.size.width - self.HUDSize.width) / 2) + self.xOffset;
	boxRect.origin.y = roundf((self.bounds.size.height - self.HUDSize.height) / 2) + self.yOffset;
	
	// Corner radius
	CGFloat radius = 10.0f;
	
    CGContextBeginPath(context);
    CGContextSetGrayFillColor(context, 0.0f, self.opacity);
    CGContextMoveToPoint(context, CGRectGetMinX(boxRect) + radius, CGRectGetMinY(boxRect));
    CGContextAddArc(context, CGRectGetMaxX(boxRect) - radius, CGRectGetMinY(boxRect) + radius, radius, 3 * M_PI / 2, 0, 0);
    CGContextAddArc(context, CGRectGetMaxX(boxRect) - radius, CGRectGetMaxY(boxRect) - radius, radius, 0, M_PI / 2, 0);
    CGContextAddArc(context, CGRectGetMinX(boxRect) + radius, CGRectGetMaxY(boxRect) - radius, radius, M_PI / 2, M_PI, 0);
    CGContextAddArc(context, CGRectGetMinX(boxRect) + radius, CGRectGetMinY(boxRect) + radius, radius, M_PI, 3 * M_PI / 2, 0);
    CGContextClosePath(context);
    CGContextFillPath(context);
}

#pragma mark -
#pragma mark Manual orientation change

- (void)deviceOrientationDidChange:(NSNotification *)notification { 
	if (!self.superview)
		return;
	
	if ([self.superview isKindOfClass:[UIWindow class]]) {
		[self setTransformForCurrentOrientation:YES];
	} else {
		self.bounds = self.superview.bounds;
		[self setNeedsDisplay];
	}
}

- (void)setTransformForCurrentOrientation:(BOOL)animated {
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	NSInteger degrees = 0;
	
	// Stay in sync with the superview
	if (self.superview) {
		self.bounds = self.superview.bounds;
		[self setNeedsDisplay];
	}
	
	if (UIInterfaceOrientationIsLandscape(orientation)) {
		if (orientation == UIInterfaceOrientationLandscapeLeft) { degrees = -90; } 
		else { degrees = 90; }
		// Window coordinates differ!
		self.bounds = CGRectMake(0, 0, self.bounds.size.height, self.bounds.size.width);
	} else {
		if (orientation == UIInterfaceOrientationPortraitUpsideDown) { degrees = 180; } 
		else { degrees = 0; }
	}
	
	NSTimeInterval animationLength = animated ? (1./3.) : 0;
	[UIView animateWithDuration:animationLength animations:^{
		self.transform = CGAffineTransformMakeRotation(degrees * M_PI / 180.0f);
	}];
}

@end

/////////////////////////////////////////////////////////////////////////////////////////////

#import <QuartzCore/QuartzCore.h>

@interface MBRoundProgressLayer : CAShapeLayer

@property (nonatomic) CGFloat progress;

@end

@implementation MBRoundProgressLayer

@dynamic progress;

+ (BOOL)needsDisplayForKey:(NSString *)key {
	return [key isEqualToString:@"progress"] || [super needsDisplayForKey:key];
}

- (void)drawInContext:(CGContextRef)context {
	CGRect allRect = self.bounds;
    CGRect circleRect = CGRectInset(allRect, 2.0f, 2.0f);

	// Draw background
	CGContextSetStrokeColorWithColor(context, self.strokeColor);
	CGContextSetFillColorWithColor(context, self.fillColor);
    CGContextSetLineWidth(context, 2.0f);
    CGContextFillEllipseInRect(context, circleRect);
    CGContextStrokeEllipseInRect(context, circleRect);
    
    // Draw progress
    CGPoint center = CGPointMake(CGRectGetMidX(allRect), CGRectGetMidY(allRect));
    CGFloat radius = floorf((allRect.size.width - 4) / 2);
    CGFloat startAngle = -M_PI / 2; // 90 degrees
    CGFloat endAngle = (self.progress * 2 * M_PI) + startAngle;
	CGContextSetFillColorWithColor(context, self.strokeColor);
    CGContextMoveToPoint(context, center.x, center.y);
    CGContextAddArc(context, center.x, center.y, radius, startAngle, endAngle, 0);
    CGContextClosePath(context);
    CGContextFillPath(context);
	
	[super drawInContext:context];
}

@end

@implementation MBRoundProgressView {
	MBRoundProgressLayer *sublayer;
}

@synthesize progress;

- (id)init {
    return [self initWithFrame:CGRectMake(0.0f, 0.0f, 37.0f, 37.0f)];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
		self.opaque = NO;
		sublayer = [MBRoundProgressLayer layer];
		sublayer.strokeColor = [[UIColor whiteColor] CGColor];
		sublayer.fillColor = [[UIColor colorWithWhite:1.0 alpha:0.1] CGColor];
		sublayer.frame = frame;
		sublayer.lineWidth = 2.0f;
		sublayer.shouldRasterize = YES;
		[self.layer addSublayer:sublayer];
    }
    return self;
}

- (CGFloat)progress {
	return sublayer.progress;
}

- (void)setProgress:(CGFloat)newProgress {
	[sublayer setProgress:newProgress];
}

@end