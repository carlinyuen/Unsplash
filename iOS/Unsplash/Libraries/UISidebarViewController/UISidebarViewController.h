//
//  UISidebarViewController.h
//  Unsplash
//
//  Created by . Carlin on 3/13/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

    /** Directions supported for sidebar entrance */
    typedef enum {
        UISidebarViewControllerDirectionLeft,
        UISidebarViewControllerDirectionRight,
    } UISidebarViewControllerDirection;

    /** Custom animation block type, targetFrame is calculated target frame location for sidebar */
    typedef void (^AnimationBlock)(CGRect targetFrame);

    /** Custom completion block type, finished refers to whether or not the animation was completed */
    typedef void (^AnimationCompletionBlock)(BOOL finished);

@interface UISidebarViewController : UIViewController

    /** Direction in which the sidebar should come from */
    @property (nonatomic, assign) UISidebarViewControllerDirection direction;

    /** Duration of slide animation when displaySidebar is called */
    @property (nonatomic, assign) CGFloat animationDuration;

    /** Margin for sidebar to slide to */
    @property (nonatomic, assign) CGFloat sidebarOffset;

    /** Custom animation and completion blocks for showing and hiding the sidebar */
    @property (nonatomic, copy) AnimationBlock showSidebarAnimation;
    @property (nonatomic, copy) AnimationCompletionBlock showSidebarCompletion;
    @property (nonatomic, copy) AnimationBlock hideSidebarAnimation;
    @property (nonatomic, copy) AnimationCompletionBlock hideSidebarCompletion;

    /** Flag for whether or not sidebar is in process of showing or is shown. This excludes if the sidebar is actually visible but is in the process of hiding. */
    @property (nonatomic, assign, readonly) BOOL sidebarIsShowing;

    /** @brief Initialize with view controller to be in the center, and the view controller to be the sidebar */
    - (id)initWithCenterViewController:(UIViewController *)center
        andSidebarViewController:(UIViewController *)sidebar;

    /** @brief Trigger show or hide sidebar with optional custom animation and completion blocks. If the animations and completions block parameters are nil, will use stored custom blocks (showSidebarAnimation, showSidebarCompletion, hideSidebarAnimation, hideSidebarCompletion) if they are set, otherwise use default animation. */
    - (void)displaySidebar:(BOOL)show
        animations:(AnimationBlock)animations
        completion:(AnimationCompletionBlock)completion;

    /** @brief Toggle displaying of sidebar */
    - (void)toggleSidebar:(id)sender;

@end
