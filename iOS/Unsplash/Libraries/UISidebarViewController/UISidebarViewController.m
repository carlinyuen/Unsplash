//
//  UISidebarViewController.m
//  Unsplash
//
//  Created by . Carlin on 3/13/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//

#import "UISidebarViewController.h"

@interface UISidebarViewController ()

    @property (nonatomic, weak) UIViewController *centerVC;
    @property (nonatomic, weak) UIViewController *sidebarVC;

@end

@implementation UISidebarViewController

/** @brief Initialize with view controller to be in the center, and the view controller to be the sidebar */
- (id)initWithCenterViewController:(UIViewController *)center andSidebarViewController:(UIViewController *)sidebar
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _centerVC = center;
        _sidebarVC = sidebar;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Hide own view
    self.view.backgroundColor = [UIColor clearColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
