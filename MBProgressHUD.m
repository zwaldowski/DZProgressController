//
//  MBProgressHUD.m
//  Version 0.4
//  Created by Matej Bukovinski on 2.4.09.
//
// This code is licensed under MIT. See LICENSE for more information. 
//

#import "MBProgressHUD.h"

static void dispatch_always_main_queue(dispatch_block_t block) {
	if ([NSThread isMainThread])
		block();
	else
		dispatch_async(dispatch_get_main_queue(), block);
}

// A progress view for showing definite progress by filling up a circle (pie chart).
@interface MBRoundProgressView : UIView
@property (nonatomic) CGFloat progress;
@end

@interface MBProgressHUD () {
	UIStatusBarStyle _statusBarStyle;
	CGSize _HUDSize;
	CGAffineTransform _rotationTransform;
}

- (void)updateProgress;
- (void)updateIndicators;
- (void)deviceOrientationDidChange:(NSNotification *)notification;

@property (nonatomic, strong) UIView *indicator;
@property (nonatomic, strong) NSDate *showStarted;

@end

@implementation MBProgressHUD

#pragma mark Constants

static const CGFloat padding = 4.0f;
static const CGFloat margin = 18.0f;
static const CGFloat opacity = 0.9f;
static const CGFloat radius = 10.0f;

static char kLabelContext;
static char kDetailLabelContext;

#pragma mark - Accessors

@synthesize mode;

@synthesize delegate;

@synthesize label, detailLabel;

@synthesize minSize;

@synthesize indicator;
@synthesize customView;

@synthesize graceTime;
@synthesize minShowTime;
@synthesize showStarted;

@synthesize removeFromSuperViewOnHide;
@synthesize progress;

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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == &kLabelContext || context == &kDetailLabelContext) {
		dispatch_always_main_queue(^{
			[self setNeedsLayout];
			[object setNeedsDisplay];
		});
		
		return;
	}
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (UILabel *)label {
	if (!label) {
		UILabel *newLabel = [[UILabel alloc] initWithFrame:self.bounds];
		newLabel.font = [UIFont boldSystemFontOfSize:16.0f];
		newLabel.adjustsFontSizeToFitWidth = NO;
        newLabel.textAlignment = UITextAlignmentCenter;
        newLabel.opaque = NO;
        newLabel.backgroundColor = [UIColor clearColor];
        newLabel.textColor = [UIColor whiteColor];
		newLabel.numberOfLines = 0;
		newLabel.lineBreakMode = UILineBreakModeClip;
		[newLabel addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionNew context:&kLabelContext];
		[newLabel addObserver:self forKeyPath:@"font" options:NSKeyValueObservingOptionNew context:&kLabelContext];
		[newLabel addObserver:self forKeyPath:@"textColor" options:NSKeyValueObservingOptionNew context:&kLabelContext];
		[newLabel addObserver:self forKeyPath:@"textAlignment" options:NSKeyValueObservingOptionNew context:&kLabelContext];
		[self addSubview:newLabel];
		label = newLabel;
	}
	return label;
}

- (UILabel *)detailLabel {
	if (!detailLabel) {
		UILabel *newLabel = [[UILabel alloc] initWithFrame:self.bounds];
        newLabel.font = [UIFont boldSystemFontOfSize:12.0f];
		newLabel.adjustsFontSizeToFitWidth = NO;
		newLabel.textAlignment = UITextAlignmentCenter;
		newLabel.opaque = NO;
        newLabel.backgroundColor = [UIColor clearColor];
		newLabel.textColor = [UIColor whiteColor];
		newLabel.numberOfLines = 0;
		newLabel.lineBreakMode = UILineBreakModeClip;
		[newLabel addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionNew context:&kDetailLabelContext];
		[newLabel addObserver:self forKeyPath:@"font" options:NSKeyValueObservingOptionNew context:&kDetailLabelContext];
		[newLabel addObserver:self forKeyPath:@"textColor" options:NSKeyValueObservingOptionNew context:&kDetailLabelContext];
		[newLabel addObserver:self forKeyPath:@"textAlignment" options:NSKeyValueObservingOptionNew context:&kDetailLabelContext];
		[self addSubview:newLabel];
		detailLabel = newLabel;
	}
	return detailLabel;
}

- (void)dealloc {
	[label removeObserver:self forKeyPath:@"text"];
	[label removeObserver:self forKeyPath:@"font"];
	[label removeObserver:self forKeyPath:@"textColor"];
	[label removeObserver:self forKeyPath:@"textAlignment"];
	[detailLabel removeObserver:self forKeyPath:@"text"];
	[detailLabel removeObserver:self forKeyPath:@"font"];
	[detailLabel removeObserver:self forKeyPath:@"textColor"];
	[detailLabel removeObserver:self forKeyPath:@"textAlignment"];
}

#pragma mark -
#pragma mark Accessor helpers

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
	NSAssert(view, @"The view used in the MBProgressHUD initializer is nil.");
	if ((self = [self initWithFrame:view.bounds])) {
		if ([view isKindOfClass:[UIWindow class]])
			[self deviceOrientationDidChange:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
	}
	return self;
}

- (void)removeFromSuperview {
    [super removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
	if (self) {
        // Set default values for properties
        self.mode = MBProgressHUDModeIndeterminate;
		self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		
        // Transparent background
        self.opaque = NO;
		
        // Make invisible for now
        self.alpha = 0.0f;
		
		_rotationTransform = CGAffineTransformIdentity;
    }
    return self;
}

#pragma mark -
#pragma mark Layout

- (void)layoutSubviews {
	CGRect frame = self.bounds, lFrame = CGRectZero, dFrame = CGRectZero, indFrame = indicator.bounds;
	CGSize newSize = CGSizeMake(indFrame.size.width + 2 * margin, indFrame.size.height + 2 * margin);
	
	indFrame.origin.x = floorf((frame.size.width - indFrame.size.width) / 2);
    indFrame.origin.y = floorf((frame.size.height - indFrame.size.height) / 2);
	
    // Add label if label text was set
    if (label.text.length) {
		// Compute label dimensions based on font metrics if size is larger than max then clip the label width
		CGSize maxSize = CGSizeMake(frame.size.width - 4 * margin, frame.size.height - newSize.height - 2 * margin);
        CGSize dims = [label.text sizeWithFont:label.font constrainedToSize:maxSize lineBreakMode:label.lineBreakMode];
		
        // Update HUD size
		if (newSize.width < dims.width + 2 * margin)
            newSize.width = dims.width + 2 * margin;
        newSize.height += dims.height + padding;
		
        // Set the label position and dimensions
		lFrame.origin.x = floor((frame.size.width - dims.width) / 2);
		lFrame.origin.y = CGRectGetMaxY(indFrame) - padding;
		lFrame.size = dims;
		
        // Move indicator to make room for the label
        indFrame.origin.y -= floor(dims.height / 2) + padding;
    }
	
	// Add details label delatils text was set
	if (detailLabel.text.length) {
		CGSize maxSize = CGSizeMake(frame.size.width - 4 * margin, frame.size.height - newSize.height - 2 * margin);
		CGSize dims = [detailLabel.text sizeWithFont:detailLabel.font constrainedToSize:maxSize lineBreakMode:detailLabel.lineBreakMode];
		
		// Update HUD size
		if (newSize.width < dims.width + 2 * margin)
			newSize.width = dims.width + 2 * margin;
		newSize.height += dims.height + padding;
		
		// Move indicator to make room for the new label
		indFrame.origin.y -= (floor(dims.height / 2 + padding / 2));
		
		// Move first label to make room for the new label
		lFrame.origin.y -= (floor(dims.height / 2 + padding / 2));
		
		// Set label position and dimensions
		dFrame.origin.x = floor((frame.size.width - dims.width) / 2);
		dFrame.origin.y = CGRectGetMaxY(lFrame) + padding * 2;
		dFrame.size = dims;
	}
	
	label.frame = lFrame;
	detailLabel.frame = dFrame;
	indicator.frame = indFrame;
	
	if (newSize.width < minSize.width)
		newSize.width = minSize.width;
	
	if (newSize.height < minSize.height)
		newSize.height = minSize.height;
		
	_HUDSize = newSize;
}

#pragma mark -
#pragma mark Showing and execution

- (void)show:(BOOL)animated {
	[self deviceOrientationDidChange:nil];
	self.alpha = 0.0f;
	self.transform = CGAffineTransformConcat(_rotationTransform, CGAffineTransformMakeScale(0.5f, 0.5f));

	NSTimeInterval length = animated ? (1./3.) : 0;
	NSTimeInterval graceTimeDelay = self.graceTime;
	
	[UIView animateWithDuration:length delay:graceTimeDelay options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction animations:^{
		self.transform = _rotationTransform;
		self.alpha = 1.0f;
	} completion:^(BOOL finished) {
		self.showStarted = [NSDate date];
	}];
}

- (void)hide:(BOOL)animated {
	[self hide:animated afterDelay:0.0];
}

- (void)hide:(BOOL)animated afterDelay:(NSTimeInterval)delay {
	if (!self.superview)
		return;
	
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^{
		NSTimeInterval length = animated ? (1./3.) : 0;
		NSTimeInterval minimumShowDelay = 0.0;
		if (showStarted)
			minimumShowDelay = self.minShowTime - [[NSDate date] timeIntervalSinceDate:showStarted];
		
		[UIView animateWithDuration:length delay:minimumShowDelay options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
			self.transform = CGAffineTransformConcat(_rotationTransform, CGAffineTransformMakeScale(1.5f, 1.5f));
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
		dispatch_sync(dispatch_get_main_queue(), ^{
			[self show:YES];
		});
		
		@autoreleasepool {
			block();
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[self hide:YES];
		});
	});
}

#pragma mark BG Drawing

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext(); 
    
    // Draw rounded HUD background rect
	CGRect boxRect = CGRectZero;
	boxRect.size = _HUDSize;
	boxRect.origin.x = roundf((self.bounds.size.width - _HUDSize.width) / 2);
	boxRect.origin.y = roundf((self.bounds.size.height - _HUDSize.height) / 2);

    CGContextBeginPath(context);
    CGContextSetGrayFillColor(context, 0.0f, opacity);
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
		
		_rotationTransform = CGAffineTransformMakeRotation(degrees * M_PI / 180.0f);
		
		if (!notification) {
			self.transform = _rotationTransform;
			return;
		}
		
		[UIView animateWithDuration:(1./3.) animations:^{
			self.transform = _rotationTransform;
		}];
	} else {
		self.bounds = self.superview.bounds;
		[self setNeedsDisplay];
	}
}

@end

/////////////////////////////////////////////////////////////////////////////////////////////

@implementation MBRoundProgressView

@synthesize progress;

- (id)init {
    return [self initWithFrame:CGRectMake(0.0f, 0.0f, 37.0f, 37.0f)];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
		self.opaque = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
	CGRect allRect = self.bounds;
    CGRect circleRect = CGRectInset(allRect, 2.0f, 2.0f);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// Draw background
	CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
	CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 0.1);
    CGContextSetLineWidth(context, 2.0f);
    CGContextFillEllipseInRect(context, circleRect);
    CGContextStrokeEllipseInRect(context, circleRect);
    
    // Draw progress
    CGPoint center = CGPointMake(CGRectGetMidX(allRect), CGRectGetMidY(allRect));
    CGFloat radius = floorf((allRect.size.width - 4) / 2);
    CGFloat startAngle = -M_PI / 2; // 90 degrees
    CGFloat endAngle = (self.progress * 2 * M_PI) + startAngle;
	CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextMoveToPoint(context, center.x, center.y);
    CGContextAddArc(context, center.x, center.y, radius, startAngle, endAngle, 0);
    CGContextClosePath(context);
    CGContextFillPath(context);
}

- (void)setProgress:(CGFloat)newProgress {
	if (progress == newProgress)
		return;
	
	progress = newProgress;
	
	[self setNeedsDisplay];
}

@end