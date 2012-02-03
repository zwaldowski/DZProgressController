//
//  MBProgressHUD.h
//  Created by Matej Bukovinski on 2.4.09.
//
// This code is licensed under MIT. See LICENSE for more information. 
//

#import <UIKit/UIKit.h>

/** When set as the HUD's custom view, the HUD will show a check image. **/
extern const id MBProgressHUDSuccessImageView;

/** When set as the HUD's custom view, the HUD will show an error image. **/
extern const id MBProgressHUDErrorImageView;

typedef enum {
    /** Progress is shown using an UIActivityIndicatorView. This is the default. */
    MBProgressHUDModeIndeterminate,
    /** Progress is shown using a MBRoundProgressView. */
	MBProgressHUDModeDeterminate,
	/** Shows a custom view */
	MBProgressHUDModeCustomView
} MBProgressHUDMode;

/** 
 * Displays a simple HUD window containing a progress indicator and two optional labels for short messages.
 *
 * This is a simple drop-in class for displaying a progress HUD view similar to Apples private UIProgressHUD class.
 * The MBProgressHUD window spans over the entire space given to it by its superview and catches all user
 * interaction on this region, thereby preventing the user operations on components below the view. The HUD itself
 * is drawn centered as a rounded semi-transparent view which resizes depending on the user specified content.
 *
 * This view supports three modes of operation:
 * - MBProgressHUDModeIndeterminate - shows a UIActivityIndicatorView
 * - MBProgressHUDModeDeterminate - shows a custom round progress indicator (MBRoundProgressView)
 * - MBProgressHUDModeCustomView - shows an arbitrary, user specified view (@see customView)
 *
 * All three modes can have an optional label. If the label has text, then the label containing the provided
 * content is placed below the indicator view.
 */
@interface MBProgressHUD : UIView

/**
 * Creates a new HUD, adds it to provided view and shows it. The counterpart to this method is hideHUDForView:animated:.
 * 
 * @param view The view that the HUD will be added to
 * @param animated If set to YES the HUD will disappear using the current animationType. If set to NO the HUD will not use
 * animations while disappearing.
 * @return A reference to the created HUD.
 *
 * @see hideHUDForView:animated:
 */
+ (MBProgressHUD *)showHUDAddedTo:(UIView *)view animated:(BOOL)animated;

/**
 * Finds a HUD subview and hides it. The counterpart to this method is showHUDAddedTo:animated:.
 *
 * @param view The view that is going to be searched for a HUD subview.
 * @param animated If set to YES the HUD will disappear using the current animationType. If set to NO the HUD will not use
 * animations while disappearing.
 * @return YES if a HUD was found and removed, NO otherwise. 
 *
 * @see hideHUDForView:animated:
 */
+ (BOOL)hideHUDForView:(UIView *)view animated:(BOOL)animated;

/**
 * The UIView (i.g., a UIImageView) to be shown when the HUD is in MBProgressHUDModeCustomView.
 * For best results use a 37 by 37 pixel view (so the bounds match the build in indicator bounds). 
 *
 * Pass `MBProgressHUDSuccessImageView` for an image view with a check.
 * Pass `MBProgressHUDErrorImageView`, for an image view with an error symbol.
 **/
@property (nonatomic, strong) UIView *customView;

/** 
 * MBProgressHUD operation mode. Switches between indeterminate (MBProgressHUDModeIndeterminate) and determinate
 * progress (MBProgressHUDModeDeterminate). The default is MBProgressHUDModeIndeterminate.
 *
 * @see MBProgressHUDMode
 */
@property (nonatomic) MBProgressHUDMode mode;

/**
 * A callback fired when the HUD is tapped.
 */
@property (nonatomic, copy) void(^wasTappedBlock)(MBProgressHUD *);

/**
 * A callback fired when the HUD is hidden.
 */
@property (nonatomic, copy) void(^wasHiddenBlock)(MBProgressHUD *);

/*
 * The show delay is the time (in seconds) that your method may run without the HUD
 * being shown. If the task finishes before the grace time runs out, the HUD will
 * not appear at all, usually if you have a very short task.
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
 * Defaults to 0.0. If you don't set one and your task might run short,
 * it is recommended to instead set a show delay time.
 *
 * @see showDelayTime
 */
@property (nonatomic) NSTimeInterval minimumShowTime;

/**
 * Removes the HUD from it's parent view when hidden. 
 * Defaults to NO. 
 */
@property (nonatomic) BOOL removeFromSuperViewOnHide;

/** 
 * A view that displays the text for the main label.
 */
@property (nonatomic, unsafe_unretained, readonly) UILabel *label;

/** 
 * The progress of the progress indicator, from 0.0 to 1.0. Defaults to 0.0. 
 */
@property (nonatomic) CGFloat progress;

/** 
 * Display the HUD.
 *
 * @param animated If set to YES the HUD will disappear using the current animationType. If set to NO the HUD will not use
 * animations while disappearing.
 */
- (void)show:(BOOL)animated;

/** 
 * Hide the HUD. This still calls the was hidden block. Use it to hide the HUD when your task completes.
 *
 * @param animated If set to YES the HUD will disappear using the current animationType. If set to NO the HUD will not use
 * animations while disappearing.
 * @see hide:afterDelay:
 */
- (void)hide:(BOOL)animated;

/** 
 * Hide the HUD after a delay. This still calls the was hidden block. Use it to hide the HUD when your task completes.
 *
 * @param animated If set to YES, the HUD will disappear using the current animation type.
 * @param completion A block to be called once the HUD has disappeared.
 * @see hide:
 * @see wasHiddenBlock
 */
- (void)hide:(BOOL)animated completion:(dispatch_block_t)completion;

/** 
 * Shows the HUD while a background task is executing in a background queue, then hides the HUD.
 *
 * This method also takes care of autorelease pools so your method does not have to be concerned with setting up a
 * pool.
 *
 * The HUD will appear and disappear using the current animationType.
 *
 * @param block A code block to be executed while the HUD is shown. This block will be executed in a global background queue.
 */
- (void)showWhileExecuting:(dispatch_block_t)block;

/**
 * Coalesces changes to the HUD (mode, view, text, fonts) into a single animation.
 *
 * This method is non-blocking. The HUD cannot be hidden while animations are ongoing.
 *
 * @param A code block of changes to the HUD. Will be executed from within a transition method.
 */
- (void)performChanges:(dispatch_block_t)animations;

@end

#pragma mark -

/**
 * A progress view for showing definite progress by filling up a circle (pie chart).
 */

@interface MBRoundProgressView : UIView

@property (nonatomic) CGFloat progress;

@end