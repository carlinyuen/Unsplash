//
//  UISidebarViewController.h
//  Unsplash
//
//  Created by . Carlin on 3/13/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

    typedef enum {
        UISidebarViewControllerDirectionLeft,
        UISidebarViewControllerDirectionRight,
    } UISidebarViewControllerDirection;

@interface UISidebarViewController : UIViewController

    @property (nonatomic, assign) UISidebarViewControllerDirection direction;

    /** @brief Initialize with view controller to be in the center, and the view controller to be the sidebar */
    - (id)initWithCenterViewController:(UIViewController *)center andSidebarViewController:(UIViewController *)sidebar;

    /** @brief Trigger show or hide sidebar */
    - (void)displaySidebar:(BOOL)show;

@end
