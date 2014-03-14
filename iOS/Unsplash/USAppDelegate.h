//
//  USAppDelegate.h
//  Unsplash
//
//  Created by . Carlin on 2/26/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UISidebarViewController.h"

    #define AppDelegate ((USAppDelegate *)[[UIApplication sharedApplication] delegate])

@interface USAppDelegate : UIResponder <UIApplicationDelegate>

    @property (strong, nonatomic) UIWindow *window;

	@property (strong, nonatomic) UISidebarViewController *viewController;
@end
