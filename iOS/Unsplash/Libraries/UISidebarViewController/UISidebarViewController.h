//
//  UISidebarViewController.h
//  Unsplash
//
//  Created by . Carlin on 3/13/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UISidebarViewController : UIViewController

    /** @brief Initialize with view controller to be in the center, and the view controller to be the sidebar */
    - (id)initWithCenterViewController:(UIViewController *)center andSidebarViewController:(UIViewController *)sidebar;

@end
