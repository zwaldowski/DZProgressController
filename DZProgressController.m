//
//  DZProgressController.m
//  DZProgressController
//
//  (c) 2012 Zachary Waldowski.
//  (c) 2009-2011 Matej Bukovinski and contributors.
//  This code is licensed under MIT. See LICENSE for more information. 
//

#import "DZProgressController.h"
#import <QuartzCore/QuartzCore.h>

#pragma mark -

@interface DZProgressControllerFrameView : UIView

@end

@implementation DZProgressControllerFrameView

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		self.opaque = NO;
		self.contentMode = UIViewContentModeRedraw;
	}
	return self;
}

- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSaveGState(context);
	CGContextSetFillColorWithColor(context, [[UIColor colorWithWhite: 0 alpha: 0.75] CGColor]);
	CGContextSetStrokeColorWithColor(context, [[UIColor colorWithWhite: 1 alpha: 0.3] CGColor]);
	CGContextSetLineWidth(context, 2);
	CGContextSetShadowWithColor(context, CGSizeMake(0, 2), 10, [[UIColor colorWithWhite:0 alpha:0.7] CGColor]);
	CGPathRef shape = [[UIBezierPath bezierPathWithRoundedRect: CGRectInset(rect, 12.0f, 12.0f) cornerRadius: 8.0f] CGPath];
	CGContextAddPath(context, shape);
	CGContextFillPath(context);
	CGContextStrokePath(context);
	CGContextRestoreGState(context);
}

@end

#pragma mark -

@interface DZRoundProgressLayer : CALayer

@property (nonatomic) CGFloat progress;

@end

@implementation DZRoundProgressLayer

@dynamic progress;

+ (BOOL)needsDisplayForKey:(NSString *)key {
	return [key isEqualToString:@"progress"] || [super needsDisplayForKey:key];
}

- (void)drawInContext:(CGContextRef)context {
	CGRect circleRect = CGRectInset(self.bounds, 1, 1);

	CGColorRef borderColor = [[UIColor whiteColor] CGColor];
	CGColorRef backgroundColor = [[UIColor colorWithWhite: 1.0 alpha: 0.15] CGColor];
		
	CGContextSetFillColorWithColor(context, backgroundColor);
	CGContextSetStrokeColorWithColor(context, borderColor);
	CGContextSetLineWidth(context, 2.0f);
	
	CGContextFillEllipseInRect(context, circleRect);
	CGContextStrokeEllipseInRect(context, circleRect);
	
	CGFloat radius = MIN(CGRectGetMidX(circleRect), CGRectGetMidY(circleRect));
	CGPoint center = CGPointMake(radius, CGRectGetMidY(circleRect));
	CGFloat startAngle = -M_PI / 2;
	CGFloat endAngle = self.progress * 2 * M_PI + startAngle;
	CGContextSetFillColorWithColor(context, borderColor);
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

#pragma mark -

@interface DZRoundProgressView : UIView

@property (nonatomic) CGFloat progress;

@end

@implementation DZRoundProgressView

+ (Class)layerClass {
	return [DZRoundProgressLayer class];
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
		self.opaque = NO;
		self.layer.contentsScale = [[UIScreen mainScreen] scale];
		[self.layer setNeedsDisplay];
    }
    return self;
}

- (void)setProgress:(CGFloat)progress {
	[(id)self.layer setProgress:progress];
}

- (CGFloat)progress {
	return [(id)self.layer progress];
}

@end

#pragma mark -

NSString *const DZProgressControllerSuccessView = @"DZProgressControllerSuccessImageView";
NSString *const DZProgressControllerErrorView = @"DZProgressControllerErrorImageView";

typedef void(^DZProgressControllerUnlockBlock)(NSTimeInterval);
typedef void(^DZProgressControllerLockBlock)(const DZProgressControllerUnlockBlock unlock);

static char DZProgressControllerLabelContext;

static void dispatch_reentrant_main(dispatch_block_t block) {
	NSCParameterAssert(block);
	dispatch_queue_t queue = dispatch_get_main_queue();
	if (dispatch_get_current_queue() == queue) {
		block();
	} else {
		dispatch_async(queue, block);
	}
}

static void dispatch_semaphore_execute(dispatch_semaphore_t semaphore, DZProgressControllerLockBlock block) {
	NSCParameterAssert(block);
	dispatch_queue_t waitingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
	dispatch_async(waitingQueue, ^{
		dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
		void (^unlockBlock)(NSTimeInterval) = ^(NSTimeInterval delay) {
			void (^signalBlock)(void) = ^{
				dispatch_semaphore_signal(semaphore);
			};
			
			if (delay == 0.0)
				signalBlock();
			else
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), waitingQueue, signalBlock);
		};
		dispatch_reentrant_main(^{
			block(unlockBlock);
		});
	});
}

#pragma mark -

@interface DZProgressController () {
	dispatch_semaphore_t _animationSemaphore;
}

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, weak) DZProgressControllerFrameView *frameView;
@property (nonatomic, weak) UIView *indicator;

@end

@implementation DZProgressController

@synthesize window = _window, frameView = _frameView, indicator = _indicator;
@synthesize mode = _mode, customView = _customView;
@synthesize showDelayTime = _showDelayTime, minimumShowTime = _minimumShowTime;
@synthesize wasTappedBlock = _wasTappedBlock, wasHiddenBlock = _wasHiddenBlock;
@synthesize label = _label;

#pragma mark - Class methods

+ (DZProgressController *)show {
	DZProgressController *hud = [self new];
	[hud show];
	return hud;
}

+ (void)showWhileExecuting:(void(^)(DZProgressController *))block {
	[self showWithText:nil whileExecuting:block];
}

+ (void)showWithText:(NSString *)statusText whileExecuting:(void(^)(DZProgressController *))block {
	if (!block) return;
	
	DZProgressController *thisHUD = [self new];
	thisHUD.label.text = statusText;
	[thisHUD showWhileExecuting:^{
		block(thisHUD);
	}];
}

#pragma mark - Setup and teardown

- (id)init {
	if (self = [super initWithNibName:nil bundle:nil]) {
		_animationSemaphore = dispatch_semaphore_create(1);
		_minimumShowTime = 1.5;
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
		
	DZProgressControllerFrameView *frame = [[DZProgressControllerFrameView alloc] initWithFrame: CGRectZero];
	frame.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview: frame];
	UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget: self action: @selector(tapGestureRecognizerFired:)];
	[frame addGestureRecognizer:recognizer];
	_frameView = frame;
	
	[frame addSubview: self.label];
	
	if (!_indicator)
		self.mode = _mode;
}

- (void)dealloc {
	if (_animationSemaphore)
		dispatch_release(_animationSemaphore);
	[_label removeObserver:self forKeyPath:@"text"];
	[_label removeObserver:self forKeyPath:@"font"];
	[_label removeObserver:self forKeyPath:@"textColor"];
	[_label removeObserver:self forKeyPath:@"textAlignment"];
}

#pragma mark - Properties

- (void)setMode:(DZProgressControllerMode)mode {
    // Don't change mode if it wasn't actually changed to prevent flickering
    if (_mode && (_mode == mode) && _indicator)
        return;
	
    _mode = mode;
	
	if (!self.isViewLoaded)
		return;
	
	UIView *indicator = nil;
	
	if (mode == DZProgressControllerModeDeterminate)
		indicator = [[DZRoundProgressView alloc] initWithFrame: CGRectMake(0, 0, 37, 37)];
	else if (mode == DZProgressControllerModeCustomView)
		indicator = self.customView;
	else if (mode == DZProgressControllerModeIndeterminate)
		indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	
	dispatch_reentrant_main(^{
		[_indicator removeFromSuperview];
		_indicator = indicator;
		[self.frameView addSubview: indicator];
		if (_mode == DZProgressControllerModeIndeterminate)
			[(UIActivityIndicatorView *)indicator startAnimating];
		[self.view setNeedsLayout];
	});
}

- (void)setCustomView:(UIView *)customView {
	if ([customView isKindOfClass:[NSString class]]) {
		if ([customView isEqual: DZProgressControllerSuccessView])
			customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"success"]];
		else if ([customView isEqual: DZProgressControllerErrorView])
			customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
		else
			return;
	}
	
	_customView = customView;
	_mode = 0;
	self.mode = DZProgressControllerModeCustomView;
}

- (CGFloat)progress {
    if (_mode != DZProgressControllerModeDeterminate)
		return 0.0f;
	
	return [(DZRoundProgressView *)_indicator progress];
}

- (void)setProgress:(CGFloat)newProgress {
	dispatch_reentrant_main(^{
		if (![_indicator isKindOfClass:[DZRoundProgressView class]])
			return;
		
		[(DZRoundProgressView *)_indicator setProgress:newProgress];
	});
}

- (UILabel *)label {
	if (!_label) {
		UILabel *label = [[UILabel alloc] initWithFrame: CGRectZero];
		label.font = [UIFont boldSystemFontOfSize:24.0f];
		label.adjustsFontSizeToFitWidth = NO;
		label.textAlignment = UITextAlignmentCenter;
		label.opaque = NO;
		label.textColor = [UIColor whiteColor];
		label.backgroundColor = nil;
		label.numberOfLines = 0;
		label.lineBreakMode = UILineBreakModeWordWrap;
		label.contentMode = UIViewContentModeLeft;
		[label addObserver: self forKeyPath: @"text" options: 0 context: &DZProgressControllerLabelContext];
		[label addObserver: self forKeyPath: @"font" options: 0 context: &DZProgressControllerLabelContext];
		[label addObserver: self forKeyPath: @"textColor" options: 0 context: &DZProgressControllerLabelContext];
		[label addObserver: self forKeyPath: @"textAlignment" options: 0 context: &DZProgressControllerLabelContext];
		_label = label;
	}
	return _label;
}

#pragma mark - UIViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	
	const CGFloat margin = 18.0f;
	const CGFloat padding = 4.0f;
	
	CGRect rect = CGRectInset(self.view.bounds, 12, 12);
	CGPoint indicatorOrigin = CGPointZero;
	
	CGSize frameSize = CGSizeMake(self.indicator.bounds.size.width + 2 * margin, self.indicator.bounds.size.height + 2 * margin);
	
	CGSize minSize = self.label.text.length ? CGSizeMake(150.0f, 125.0f) : CGSizeMake(80.0f, 80.0f);
	CGSize maxSize = CGSizeMake(rect.size.width - 4 * margin, rect.size.height - frameSize.height - 2 * margin);
	
	CGSize labelSize = [self.label.text sizeWithFont: self.label.font constrainedToSize:maxSize lineBreakMode: self.label.lineBreakMode];
	
	if (labelSize.height) {
		if (frameSize.width < labelSize.width + 2 * margin)
			frameSize.width = labelSize.width + 2 * margin;
		frameSize.height += labelSize.height + margin;
	}
	
	if (frameSize.width < minSize.width)
		frameSize.width = minSize.width;
	
	if (frameSize.height < minSize.height)
		frameSize.height = minSize.height;
	
	frameSize.width += 12;
	frameSize.height += 12;
	
	indicatorOrigin.x = roundf((frameSize.width / 2) - CGRectGetMidX(self.indicator.bounds));
    indicatorOrigin.y = roundf((frameSize.height / 2) - CGRectGetMidY(self.indicator.bounds));
	
	if (labelSize.height)
        indicatorOrigin.y -= floor(labelSize.height / 2) + padding;
	
	self.frameView.frame = (CGRect){{round(CGRectGetMidX(rect) - frameSize.width/2), round(CGRectGetMidY(rect) - frameSize.height/2)}, frameSize};
	self.indicator.frame = (CGRect){indicatorOrigin, self.indicator.bounds.size};
	self.label.frame = (CGRect){{floor((frameSize.width - labelSize.width) / 2), floor(CGRectGetMaxY(self.indicator.frame) + 3 * padding)}, labelSize };
}

- (BOOL)isVisible {
	return !!self.view.window;
}

#pragma mark - Actions

- (void)show {
	UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	window.backgroundColor = [UIColor clearColor];
	window.windowLevel = UIWindowLevelAlert;
	window.rootViewController = self;
	self.window = window;
	
	self.view.alpha = 0.00001;
	self.frameView.transform = CGAffineTransformMakeScale(0.5, 0.5);
	
	[window makeKeyAndVisible];
	
	dispatch_semaphore_execute(_animationSemaphore, ^(const DZProgressControllerUnlockBlock unlock){
		[UIView animateWithDuration: (1./3.)
							  delay: self.showDelayTime
							options: UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowAnimatedContent
						 animations: ^{
							 self.frameView.transform = CGAffineTransformIdentity;
							 self.view.alpha = 1.0f;
					   } completion: ^(BOOL finished) {
							 unlock(self.minimumShowTime);
					   }];
	});
}

- (void)hide {
	dispatch_semaphore_execute(_animationSemaphore, ^(const DZProgressControllerUnlockBlock unlock){
		[UIView animateWithDuration: (1./3.)
							  delay: 0.0
							options: UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowAnimatedContent
						 animations: ^{
							 self.view.transform = CGAffineTransformMakeScale(0.00001, 0.00001);
							 self.view.alpha = 0.00001;
					   } completion:^(BOOL finished) {
							 unlock(0.0);
							 
							 if (_wasHiddenBlock)
								 _wasHiddenBlock(self);
							 
							 self.window.rootViewController = nil;
							 self.window = nil;
					   }];
	});
}

- (void)showWhileExecuting:(void(^)(void))block {
	NSCParameterAssert(block);
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self show];
		});
		
		@autoreleasepool {
			block();
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[self hide];
		});
	});
}

- (void)performChanges:(void(^)(void))animations {
	NSCParameterAssert(animations);
	dispatch_semaphore_execute(_animationSemaphore, ^(const DZProgressControllerUnlockBlock unlock) {
		[UIView transitionWithView: self.frameView
						  duration: (1./3.)
						   options: UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionFlipFromRight | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowAnimatedContent
						animations: animations
						completion: ^(BOOL finished) {
							unlock(self.minimumShowTime);
						}];
	});
}

#pragma mark - Internal

- (void)tapGestureRecognizerFired:(UITapGestureRecognizer *)recognizer {
	if (recognizer.state != UIGestureRecognizerStateRecognized)
		return;
	
	if (_wasTappedBlock)
		_wasTappedBlock(self);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == &DZProgressControllerLabelContext) {
		if (!self.view.window)
			return;
		
		// Only relayout if we we aren't animating, i.e., if we can get the animation lock.
		if (dispatch_semaphore_wait(_animationSemaphore, DISPATCH_TIME_NOW) == 0) {
			dispatch_reentrant_main(^{
				[self.view setNeedsLayout];
			});
			dispatch_semaphore_signal(_animationSemaphore);
		}
		
		return;
	}
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

@end
