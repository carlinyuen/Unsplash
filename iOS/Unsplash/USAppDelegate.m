//
//  USAppDelegate.m
//  Unsplash
//
//  Created by . Carlin on 2/26/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//

#import "USAppDelegate.h"

#import "USViewController.h"
#import "USMenuViewController.h"

    #define TEXT_NOTIFICATION_REMINDER_TEXT @"New beautiful free images hot off the press from ooomf!"
    #define TEXT_NOTIFICATION_REMINDER_TITLE @"Check it out!"

    #define SIZE_SIDEBAR_WIDTH 240

    #define TIME_NOTIFICATION_REMINDER_INTERVAL 10 * TIME_ONE_DAY

@implementation USAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    // Hide status bar
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];

    // Create base view controller
    USViewController *rootVC = [[USViewController alloc] initWithNibName:@"USViewController" bundle:nil];

    // Create menu sidebar controller
    USMenuViewController *menuVC = [[USMenuViewController alloc] initWithNibName:@"USMenuViewController" bundle:nil];
    menuVC.delegate = rootVC;

    self.viewController = [[UISidebarViewController alloc]
        initWithCenterViewController:rootVC
        andSidebarViewController:menuVC];
    self.viewController.sidebarWidth = SIZE_SIDEBAR_WIDTH;
    self.window.rootViewController = self.viewController;

    // Handle notifications
    UILocalNotification *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (notification) {
        [self application:application didReceiveLocalNotification:notification];
    }

    // Create one-time local notification for reminder
    if (![[NSUserDefaults standardUserDefaults] boolForKey:ONCE_KEY_APP_OPENED])
    {
        debugLog(@"First-time use: setting monthly reminder");

        // Set local notification for an update every 10 days (re:unsplash.com)
        notification = [UILocalNotification new];
        notification.soundName = UILocalNotificationDefaultSoundName;
        notification.alertBody = TEXT_NOTIFICATION_REMINDER_TEXT;
        notification.alertAction = TEXT_NOTIFICATION_REMINDER_TITLE;
        notification.applicationIconBadgeNumber = 1;
        notification.repeatInterval = NSCalendarUnitMonth;
        notification.fireDate = [NSDate dateWithTimeInterval:TIME_NOTIFICATION_REMINDER_INTERVAL sinceDate:[NSDate date]];

        // Update flag for one time setting
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:ONCE_KEY_APP_OPENED];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    [self.window makeKeyAndVisible];
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

    // Tell root viewcontroller to redisplay
    [self.viewController viewWillAppear:true];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


#pragma mark - Notifications

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    debugLog(@"receivedLocalNotification: %@", notification.userInfo);
}

@end
