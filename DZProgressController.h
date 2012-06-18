//
//  DZProgressController.h
//  DZProgressController
//
//  (c) 2012 Zachary Waldowski.
//  (c) 2009-2011 Matej Bukovinski and contributors.
//  This code is licensed under MIT. See LICENSE for more information. 
//

#import <UIKit/UIKit.h>

/** When set as the HUD's custom view, the HUD will show a check image. **/
extern const id DZProgressControllerSuccessView;

/** When set as the HUD's custom view, the HUD will show an error image. **/
extern const id DZProgressControllerErrorView;

typedef enum {
    /** Progress is shown using an UIActivityIndicatorView. This is the default. */
    DZProgressControllerModeIndeterminate,
    /** Progress is shown using a DZRoundProgressView. */
	DZProgressControllerModeDeterminate,
	/** Shows a custom view */
	DZProgressControllerModeCustomView
} DZProgressControllerMode;

@interface DZProgressController : UIViewController <UIAppearanceContainer>

/**
 * Creates a new HUD and shows it on the current window.
 * 
 * @returns A reference to the created HUD.
 *
 * @see showOnView:
 * @see hide
 */
+ (DZProgressController *)show;

/**
 * Shows a HUD on the current window using while executing a block in the background.
 *
 * The block is executed from a separate queue unrelated to the UI main thread. The HUD is passed
 * as an argument to the block for progress updates, changes, and so on. The HUD should not be
 * dismissed from within the block; instead, bail out using a return statement.
 *
 * @param block A code block to be executed. Should not be NULL.
 *
 * @see showWithText:whileExecuting:
 */
+ (void)showWhileExecuting:(void(^)(DZProgressController *))block;

/**
 * Shows a HUD on the current window using while executing a block in the background.
 *
 * The block is executed from a separate queue unrelated to the UI main thread. The HUD is passed
 * as an argument to the block for progress updates, changes, and so on. The HUD should not be
 * dismissed from within the block; instead, bail out using a return statement.
 *
 * @param statusText The text for the main label. Send an empty string to not show the label at all.
 * @param block A code block to be executed. Should not be NULL.
 *
 * @see label
 * @see showWhileExecuting:
 */
+ (void)showWithText:(NSString *)statusText whileExecuting:(void(^)(DZProgressController *))block;

/**
 * The view to be shown when the HUD is set to DZProgressControllerModeCustomView.
 * For best results, use a 37x37 pt view (so the bounds match the default indicator bounds). 
 *
 * Pass `DZProgressControllerSuccessView` for an image view with a check.
 * Pass `DZProgressControllerErrorView`, for an image view with an error symbol.
 **/
@property (nonatomic, strong) UIView *customView;

/** 
 * HUD operation mode. The default is DZProgressControllerModeModeIndeterminate.
 *
 * @see DZProgressControllerMode
 */
@property (nonatomic) DZProgressControllerMode mode;

/**
 * Returns the label used for the main textual content of the HUD.
 */
@property (nonatomic, strong, readonly) UILabel *label;

/**
 * The progress of the progress indicator, from 0.0 to 1.0. Always animated.
 */
@property (nonatomic) CGFloat progress;

/** A callback fired when the HUD is tapped. */
@property (nonatomic, copy) void(^wasTappedBlock)(DZProgressController *);

/** A callback fired when the HUD is hidden. */
@property (nonatomic, copy) void(^wasHiddenBlock)(DZProgressController *);

/*
 * The show delay is the time (in seconds) that your method may run without the HUD
 * being shown. If the task finishes before the grace time runs out, the HUD will
 * not appear at all.
 *
 * Defaults to 0. If you don't set one and still might have a short task,
 * it is recommended to set a minimum show time instead.
 *
 * @see minimumShowTime
 */
@property (nonatomic) NSTimeInterval showDelayTime;

/**
 * The minimum time (in seconds) that the HUD is shown. 
 * This avoids the problem of the HUD being shown and than instantly hidden.
 *
 * Defaults to 1.5. If you don't set one and your task might run short,
 * it is recommended to instead set a show delay time.
 *
 * @see showDelayTime
 */
@property (nonatomic) NSTimeInterval minimumShowTime;

/**
 * Returns whether or not the HUD is currently visible.
 */
@property (nonatomic, readonly, getter = isVisible) BOOL visible;

/**
 * Display the HUD. All user interaction with the app is disabled while the HUD is shown.
 */
- (void)show;

/** 
 * Hide the HUD when your task completes.
 */
- (void)hide;

/** 
 * Shows the HUD while a task is executing in a background queue, then hides it.
 *
 * This method also takes care of an autorelease pool so your method does not have
 * to be concerned with setting one up.
 *
 * @param block A code block to be executed while the HUD is shown.
 */
- (void)showWhileExecuting:(void(^)(void))block;

/**
 * Coalesces changes to the HUD (mode, view, text, fonts) into a single animation.
 *
 * This method is non-blocking, but the HUD cannot be hidden while animations are ongoing.
 *
 * @param A code block of changes to the HUD. Will be executed from within a transition method.
 */
- (void)performChanges:(void(^)(void))animations;

@end
