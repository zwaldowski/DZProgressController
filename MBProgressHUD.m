//
//  MBProgressHUD.m
//  Version 0.4
//  Created by Matej Bukovinski on 2.4.09.
//
// This code is licensed under MIT. See LICENSE for more information. 
//

#import "MBProgressHUD.h"

#pragma mark Constants and Functions

typedef void(^MBUnlockBlock)(NSTimeInterval);
typedef void(^MBLockBlock)(const MBUnlockBlock unlock);

NSString *const MBProgressHUDSuccessImageView = @"MBProgressHUDSuccessImageView";
NSString *const MBProgressHUDErrorImageView = @"MBProgressHUDErrorImageView";

static const CGFloat padding = 4.0f;
static const CGFloat margin = 18.0f;
static const CGFloat opacity = 0.77f;
static const CGFloat radius = 10.0f;

static char kLabelContext;

static void dispatch_reentrant_main(dispatch_block_t block) {
	NSCParameterAssert(block);
	dispatch_queue_t queue = dispatch_get_main_queue();
	if (dispatch_get_current_queue() == queue) {
		block();
	} else {
		dispatch_async(queue, block);
	}
}

static void dispatch_semaphore_execute(dispatch_semaphore_t semaphore, MBLockBlock block) {
	NSCParameterAssert(block);
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
		dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
		void (^unlockBlock)(NSTimeInterval) = ^(NSTimeInterval delay){
			dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
			dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
				dispatch_semaphore_signal(semaphore);
			});
		};
		dispatch_reentrant_main(^{
			block(unlockBlock);
		});
	});
}

#pragma mark -

@implementation MBProgressHUD {
	UIStatusBarStyle _statusBarStyle;
	CGRect _HUDRect;
	CGAffineTransform _rotationTransform;
	__unsafe_unretained UIView *_indicator;
	dispatch_semaphore_t _animationSemaphore;
}

#pragma mark Accessors

@synthesize mode;
@synthesize customView;
@synthesize wasTappedBlock, wasHiddenBlock;
@synthesize showDelayTime, minimumShowTime;
@synthesize label;

#pragma mark - Class methods

+ (MBProgressHUD *)show {
	return [self showOnView:nil];
}

+ (MBProgressHUD *)showOnView:(UIView *)view {
	MBProgressHUD *hud = [MBProgressHUD new];
	[hud showOnView:view];
	return hud;
}

+ (void)showWhileExecuting:(void(^)(MBProgressHUD *))block {
	[self showWithText:nil whileExecuting:block];
}

+ (void)showWithText:(NSString *)statusText whileExecuting:(void(^)(MBProgressHUD *))block {
	if (!block) return;
	
	MBProgressHUD *thisHUD = [self new];
	thisHUD.label.text = statusText;
	[thisHUD showWhileExecuting:^{
		block(thisHUD);
	}];
}

#pragma mark - Private notifications

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == &kLabelContext) {
		if (!self.superview)
			return;
		
		// Only relayout if we we aren't animating, i.e., if we can get the animation lock.
		if (dispatch_semaphore_wait(_animationSemaphore, DISPATCH_TIME_NOW) == 0) {
			dispatch_reentrant_main(^{
				[self setNeedsLayout];
			});
			dispatch_semaphore_signal(_animationSemaphore);
		}
		
		return;
	}
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)tapGestureRecognizerFired:(UITapGestureRecognizer *)recognizer {
	if (recognizer.state != UIGestureRecognizerStateRecognized)
		return;
	
	if (!CGRectContainsPoint(_HUDRect, [recognizer locationInView:self]))
		return;
	
	if (wasTappedBlock)
		wasTappedBlock(self);
}

- (void)reloadOrientation:(NSNotification *)notification { 
	if (!self.superview)
		return;
	
	// Stay in sync with the superview
	self.frame = self.superview.bounds;
	
	if ([self.superview isKindOfClass:[UIWindow class]]) {
		UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
		NSInteger degrees = 0;
		
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
				
		[UIView animateWithDuration:(1./3.) delay:0.0 options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowAnimatedContent animations:^{
			self.transform = _rotationTransform;
		} completion:NULL];
	}
}

- (void)reloadIndicatorView:(UIView *)newIndicator {
	if (!newIndicator)
		newIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	
	[_indicator removeFromSuperview];
	_indicator = newIndicator;
	[self addSubview:newIndicator];
	if (mode == MBProgressHUDModeIndeterminate)
		[(UIActivityIndicatorView *)newIndicator startAnimating];
	[self setNeedsLayout];
}

#pragma mark - Setup and teardown

- (id)initWithFrame:(CGRect)frame {
	return [self init];
}

- (id)init {
	if ((self = [super initWithFrame:CGRectZero])) {		
		_animationSemaphore = dispatch_semaphore_create(1);
		_rotationTransform = CGAffineTransformIdentity;

        // Set default values for properties
		[self reloadIndicatorView:nil];
		self.minimumShowTime = 1.5;
		
		
        // UIView properties
		self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        self.opaque = NO;
        self.alpha = 0.0f;
		
		UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizerFired:)];
		[self addGestureRecognizer:recognizer];
    }
    return self;
}

- (void)dealloc {
	if (_animationSemaphore)
		dispatch_release(_animationSemaphore);
	[label removeObserver:self forKeyPath:@"text"];
	[label removeObserver:self forKeyPath:@"font"];
	[label removeObserver:self forKeyPath:@"textColor"];
	[label removeObserver:self forKeyPath:@"textAlignment"];
}

#pragma mark - Lifecycle methods

- (void)willMoveToSuperview:(UIView *)newSuperview {
	[super willMoveToSuperview:newSuperview];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadOrientation:) name:UIDeviceOrientationDidChangeNotification object:nil];
	[self reloadOrientation:nil];
}

- (void)removeFromSuperview {
    [super removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

#pragma mark - Showing and hiding

- (void)show {
	[self showOnView:nil];
}

- (void)showOnView:(UIView *)view {
	if (!self.superview && !view)
		view = [[[UIApplication sharedApplication] delegate] respondsToSelector:@selector(window)] ? [[[UIApplication sharedApplication] delegate] window] : [[[UIApplication sharedApplication] windows] objectAtIndex:0];
	
	dispatch_semaphore_execute(_animationSemaphore, ^(const MBUnlockBlock unlock) {
		if (!self.superview)				
			[view addSubview:self];
		
		[self reloadOrientation:nil];
		self.alpha = 0.0f;
		self.transform = CGAffineTransformConcat(_rotationTransform, CGAffineTransformMakeScale(0.5f, 0.5f));
		
		[UIView animateWithDuration: (1./3.)
							  delay: self.showDelayTime
							options: (UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowAnimatedContent)
						 animations: ^{
							 self.transform = _rotationTransform;
							 self.alpha = 1.0f;
					   } completion: ^(BOOL finished) {
						   unlock(self.minimumShowTime);
					   }];
	});
}

- (void)hide {
	dispatch_semaphore_execute(_animationSemaphore, ^(const MBUnlockBlock unlock) {
		if (!self.superview)
			return;
		
		[UIView animateWithDuration: (1./3.)
							  delay: 0.0
							options: (UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowAnimatedContent)
						 animations: ^{
							 self.transform = CGAffineTransformConcat(_rotationTransform, CGAffineTransformMakeScale(1.5f, 1.5f));
							 self.alpha = 0.0f;
					   } completion:^(BOOL finished) {
						   unlock(0.0);
						
						   if (wasHiddenBlock)
							   wasHiddenBlock(self);
						
						   if (self.superview)
							   [self removeFromSuperview];
					   }];
	});
}

- (void)showWhileExecuting:(dispatch_block_t)block {
	NSCParameterAssert(block);

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[self show];
		
		@autoreleasepool {
			block();
		}
		
		[self hide];
	});
}

- (void)performChanges:(dispatch_block_t)animations {
	NSCParameterAssert(animations);
	dispatch_semaphore_execute(_animationSemaphore, ^(const MBUnlockBlock unlock) {
		[UIView transitionWithView:self
						  duration:(1./3.)
						   options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionTransitionFlipFromRight|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionLayoutSubviews|UIViewAnimationOptionAllowAnimatedContent
						animations:animations
						completion:^(BOOL finished){ unlock(self.minimumShowTime); }];
	});
}

#pragma mark - Layout and drawing

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext(); 
    CGContextBeginPath(context);
    CGContextSetGrayFillColor(context, 0.0f, opacity);
    CGContextMoveToPoint(context, CGRectGetMinX(_HUDRect) + radius, CGRectGetMinY(_HUDRect));
    CGContextAddArc(context, CGRectGetMaxX(_HUDRect) - radius, CGRectGetMinY(_HUDRect) + radius, radius, 3 * M_PI / 2, 0, 0);
    CGContextAddArc(context, CGRectGetMaxX(_HUDRect) - radius, CGRectGetMaxY(_HUDRect) - radius, radius, 0, M_PI / 2, 0);
    CGContextAddArc(context, CGRectGetMinX(_HUDRect) + radius, CGRectGetMaxY(_HUDRect) - radius, radius, M_PI / 2, M_PI, 0);
    CGContextAddArc(context, CGRectGetMinX(_HUDRect) + radius, CGRectGetMinY(_HUDRect) + radius, radius, M_PI, 3 * M_PI / 2, 0);
    CGContextClosePath(context);
    CGContextFillPath(context);
}

- (void)layoutSubviews {
	CGRect frame = self.bounds, lFrame = CGRectZero, indFrame = _indicator.bounds;
	CGSize newSize = CGSizeMake(indFrame.size.width + 2 * margin, indFrame.size.height + 2 * margin);
	
	if (CGRectEqualToRect(frame, self.window.bounds)) {
		CGFloat statusHeight = CGRectGetHeight([[UIApplication sharedApplication] statusBarFrame]);
		frame.origin.y += statusHeight;
		frame.size.height -= statusHeight;
	}
	
	indFrame.origin.x = roundf(CGRectGetMidX(frame) - CGRectGetMidX(indFrame));
    indFrame.origin.y = roundf(CGRectGetMidY(frame) - CGRectGetMidY(indFrame));
	
	CGSize minSize = CGSizeMake(80.0f, 80.0f);
	
    // Add label if label text was set
    if (label.text.length) {
		minSize = CGSizeMake(150.0f, 125.0f);
		
		// Compute label dimensions based on font metrics if size is larger than max then clip the label width
		CGSize maxSize = CGSizeMake(frame.size.width - 4 * margin, frame.size.height - newSize.height - 2 * margin);
        CGSize dims = [label.text sizeWithFont:label.font constrainedToSize:maxSize lineBreakMode:label.lineBreakMode];
		
        // Update HUD size
		if (newSize.width < dims.width + 2 * margin)
            newSize.width = dims.width + 2 * margin;
        newSize.height += dims.height + margin;
		
        // Move indicator to make room for the label
        indFrame.origin.y -= floor(dims.height / 2) + padding;
		
        // Set the label position and dimensions
		lFrame.origin.x = floor((frame.size.width - dims.width) / 2);
		lFrame.origin.y = CGRectGetMaxY(indFrame) + 2 * padding;
		lFrame.size = dims;
    }
	
	label.frame = lFrame;
	_indicator.frame = indFrame;
	
	if (newSize.width < minSize.width)
		newSize.width = minSize.width;
	
	if (newSize.height < minSize.height)
		newSize.height = minSize.height;
	
	_HUDRect = (CGRect){{roundf(CGRectGetMidX(frame) - newSize.width/2), roundf(CGRectGetMidY(frame) - newSize.height/2)}, newSize};
}

#pragma mark - Accessors

- (void)setMode:(MBProgressHUDMode)newMode {
    // Don't change mode if it wasn't actually changed to prevent flickering
    if (mode && (mode == newMode)) {
        return;
    }
	
    mode = newMode;
	
	UIView *newIndicator = nil;
	
	if (mode == MBProgressHUDModeDeterminate)
		newIndicator = [MBRoundProgressView new];
	else if (mode == MBProgressHUDModeIndeterminate)
		newIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	else if (mode == MBProgressHUDModeCustomView && self.customView)
		newIndicator = self.customView;
	
	dispatch_reentrant_main(^{
		[self reloadIndicatorView:newIndicator];
	});
}

- (void)setCustomView:(UIView *)newCustomView {
	if ([newCustomView isKindOfClass:[NSString class]]) {
		if ([newCustomView isEqual:MBProgressHUDSuccessImageView])
			newCustomView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"success"]];
		else if ([newCustomView isEqual:MBProgressHUDErrorImageView])
			newCustomView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
		else
			return;
	}
	
	customView = newCustomView;
	
	dispatch_reentrant_main(^{
		[self reloadIndicatorView:newCustomView];
	});
}

- (CGFloat)progress {
    if (mode != MBProgressHUDModeDeterminate)
		return 0.0f;
	
	return [(MBRoundProgressView *)_indicator progress];
}

- (void)setProgress:(CGFloat)newProgress {
	[self setProgress:newProgress animated:NO];
}

- (void)setProgress:(CGFloat)newProgress animated:(BOOL)animated {
    if (mode != MBProgressHUDModeDeterminate)
		return;
	
	dispatch_reentrant_main(^{
		if (![_indicator isKindOfClass:[MBRoundProgressView class]])
			return;
		
		[(MBRoundProgressView *)_indicator setProgress:newProgress animated:animated];
	});
}

- (UILabel *)label {
	if (!label) {
		UILabel *newLabel = [[UILabel alloc] initWithFrame:self.bounds];		
		newLabel.font = [UIFont boldSystemFontOfSize:24.0f];
		newLabel.adjustsFontSizeToFitWidth = NO;
        newLabel.textAlignment = UITextAlignmentCenter;
        newLabel.opaque = NO;
        newLabel.backgroundColor = nil;
        newLabel.textColor = [UIColor whiteColor];
		newLabel.numberOfLines = 0;
		newLabel.lineBreakMode = UILineBreakModeWordWrap;
		newLabel.contentMode = UIViewContentModeLeft;
		[newLabel addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionNew context:&kLabelContext];
		[newLabel addObserver:self forKeyPath:@"font" options:NSKeyValueObservingOptionNew context:&kLabelContext];
		[newLabel addObserver:self forKeyPath:@"textColor" options:NSKeyValueObservingOptionNew context:&kLabelContext];
		[newLabel addObserver:self forKeyPath:@"textAlignment" options:NSKeyValueObservingOptionNew context:&kLabelContext];
		[self addSubview:newLabel];
		label = newLabel;
	}
	return label;
}

@end

#pragma mark -

#import <QuartzCore/QuartzCore.h>

@interface MBRoundProgressLayer : CALayer

@property (nonatomic) CGFloat progress;

@end

@implementation MBRoundProgressLayer

@dynamic progress;

+ (BOOL)needsDisplayForKey:(NSString *)key {
	return [key isEqualToString:@"progress"] || [super needsDisplayForKey:key];
}

- (void)drawInContext:(CGContextRef)context {
	CGRect circleRect = self.bounds;
	
	CGFloat radius = CGRectGetMidX(circleRect);
	CGPoint center = CGPointMake(radius, CGRectGetMidY(circleRect));
	CGFloat startAngle = -M_PI / 2;
	CGFloat endAngle = self.progress * 2 * M_PI + startAngle;
	CGContextSetFillColorWithColor(context, self.borderColor);
	CGContextMoveToPoint(context, center.x, center.y);
	CGContextAddArc(context, center.x, center.y, radius, startAngle, endAngle, 0);
	CGContextClosePath(context);
	CGContextFillPath(context);
	
	[super drawInContext:context];
}

- (id)actionForKey:(NSString *) aKey {
    if ([aKey isEqualToString:@"progress"]) {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:aKey];
        animation.fromValue = [self.presentationLayer valueForKey:aKey];
        return animation;
    }
	return [super actionForKey:aKey];
}

@end

@implementation MBRoundProgressView

+ (Class)layerClass {
	return [MBRoundProgressLayer class];
}

- (id)init {
    return [self initWithFrame:CGRectMake(0.0f, 0.0f, 37.0f, 37.0f)];
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
		self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
		self.layer.borderWidth = 2.0f;
		self.layer.borderColor = [[UIColor whiteColor] CGColor];
		self.layer.cornerRadius = CGRectGetMidX(frame);
		self.layer.backgroundColor = [[UIColor colorWithWhite:1.0 alpha:0.15] CGColor];
    }
    return self;
}

- (void)setProgress:(CGFloat)progress {
	[self setProgress:progress animated:NO];
}

- (void)setProgress:(CGFloat)progress animated:(BOOL)animated {
	NSTimeInterval length = animated ? (1./3.) : 0.0;
	
	[UIView animateWithDuration:length delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
		[(MBRoundProgressLayer *)self.layer setProgress:progress];
	} completion:NULL];
}

- (CGFloat)progress {
	return [(MBRoundProgressLayer *)self.layer progress];
}

@end