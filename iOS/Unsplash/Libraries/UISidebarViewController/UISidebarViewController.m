//
//  UISidebarViewController.m
//  Unsplash
//
//  Created by . Carlin on 3/13/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//

#import "UISidebarViewController.h"

#import <QuartzCore/QuartzCore.h>

@interface UISidebarViewController () <
    UIGestureRecognizerDelegate
>

    /** UIViewControllers to manipulate */
    @property (nonatomic, strong) UIViewController *centerVC;
    @property (nonatomic, strong) UIViewController *sidebarVC;

    /** For detecting pan gesture for sidebar */
    @property (nonatomic, strong) UIPanGestureRecognizer *panGesture;

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

    // Setup
    [self setupCenterView];
    [self setupSidebarView];
    [self setupViewOverlap];
    [self setupGestures];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // Update bounds of sidebar and center view
    if (self.centerVC) {
        self.centerVC.view.frame = self.view.bounds;
    }
    if (self.sidebarVC) {
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    // Remove observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Setup

- (void)setupCenterView
{
    // Create centerVC if does not exist
    if (!self.centerVC)
    {
        self.centerVC = [UIViewController new];
        self.centerVC.view.backgroundColor = [UIColor whiteColor];
        self.centerVC.view.frame = self.view.bounds;
    }

    // Setup centerVC
    CGRect frame = self.centerVC.view.frame;
    frame.origin = CGPointMake(0, 0);
    self.centerVC.view.frame = frame;

    // Add to this view
    [self.view addSubview:self.centerVC.view];
    [self addChildViewController:self.centerVC];
    [self.centerVC didMoveToParentViewController:self];
}

- (void)setupSidebarView
{
    // Create sidebarVC if does not exist
    if (!self.sidebarVC)
    {
        self.sidebarVC = [UIViewController new];
        self.sidebarVC.view.backgroundColor = [UIColor darkGrayColor];
        self.sidebarVC.view.frame = self.view.bounds;
    }

    // Setup sidebarVC
    CGRect frame = self.sidebarVC.view.frame;
    frame.origin = (self.direction == UISidebarViewControllerDirectionLeft)
        ? CGPointMake(-CGRectGetWidth(frame), 0)
        : CGPointMake(CGRectGetWidth(self.view.bounds), 0);
    self.sidebarVC.view.frame = frame;
    
    // Add to this view
    [self.view addSubview:self.sidebarVC.view];
    [self addChildViewController:self.sidebarVC];
    [self.sidebarVC didMoveToParentViewController:self];
}

- (void)setupViewOverlap
{
    [self.centerVC.view addSubview:self.sidebarVC.view];
}

/** @brief Creates and sets up a whole new gesture recognizer and attaches it to the centerVC view */
- (void)setupGestures
{
    // If old gesture exists, remove it
    if (self.panGesture) {
        [self.panGesture removeTarget:self action:@selector(sidebarPanned:)];
        self.panGesture = nil;
    }

    // Regular UIPanGestureRecognizer for < iOS 7
    if (deviceOSVersionLessThan(iOS7)) {
        self.panGesture = [[UIPanGestureRecognizer alloc]
            initWithTarget:self action:@selector(sidebarPanned:)];
    }
    else    // UIScreenEdgePanGestureRecognizer
    {
        UIScreenEdgePanGestureRecognizer *edgePan = [[UIScreenEdgePanGestureRecognizer alloc]
            initWithTarget:self action:@selector(sidebarPanned:)];
        edgePan.edges = UIRectEdgeLeft | UIRectEdgeRight;
        self.panGesture = edgePan;
    }

    // Configure rest of the gesture
    [self.panGesture setMinimumNumberOfTouches:1];
    [self.panGesture setMaximumNumberOfTouches:1];
    [self.panGesture setDelegate:self];

    // Attach gesture to center view
    [self.centerVC.view addGestureRecognizer:self.panGesture];
}


#pragma mark - Class Methods

/** @brief Trigger show or hide sidebar */
- (void)displaySidebar:(BOOL)show
{

}


#pragma mark - Event Handlers

- (void)sidebarPanned:(UIPanGestureRecognizer *)gesture
{
}


#pragma mark - Protocols
#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return true;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return true;
}


@end
