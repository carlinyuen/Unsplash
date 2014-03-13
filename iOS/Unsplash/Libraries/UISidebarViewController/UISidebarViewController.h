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

@interface UISidebarViewController : UIViewController

    /** Direction in which the sidebar should come from */
    @property (nonatomic, assign) UISidebarViewControllerDirection direction;

    /** Duration of slide animation when displaySidebar is called */
    @property (nonatomic, assign) CGFloat animationDuration;

    /** Margin for sidebar to slide to */
    @property (nonatomic, assign) CGFloat sidebarOffset;

    /** Flag for whether or not sidebar is in process of showing or is shown. This excludes if the sidebar is actually visible but is in the process of hiding. */
    @property (nonatomic, assign, readonly) BOOL sidebarIsShowing;

    /** @brief Initialize with view controller to be in the center, and the view controller to be the sidebar */
    - (id)initWithCenterViewController:(UIViewController *)center andSidebarViewController:(UIViewController *)sidebar;

    /** @brief Trigger show or hide sidebar */
    - (void)displaySidebar:(BOOL)show animations:(void(^)(CGRect targetFrame))animations completion:(void(^)(BOOL finished))completion;

    /** @brief Toggle displaying of sidebar */
    - (void)toggleSidebar:(id)sender;

@end
