//
//  USImageViewController.m
//  Unsplash
//
//  Created by . Carlin on 2/26/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//

#import "USImageViewController.h"

@interface USImageViewController ()

@end

@implementation USImageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    // Scrollview
    self.scrollView.backgroundColor = [UIColor blackColor];
	self.scrollView.minimumZoomScale = 1;
	self.scrollView.maximumZoomScale = 10.0;
	self.scrollView.delaysContentTouches = false;
	self.scrollView.delegate = self;

    // Imageview
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;

    // Tap Gesture to close
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
		initWithTarget:self action:@selector(imageTapped:)];
	tap.delaysTouchesBegan = false;
	tap.delaysTouchesEnded = false;
    [self.scrollView addGestureRecognizer:tap];

    // Adding parallax effect for iOS 7
    if (!deviceOSVersionLessThan(iOS7))
    {
        // Set vertical effect
        UIInterpolatingMotionEffect *verticalMotionEffect
            = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
            type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
        verticalMotionEffect.minimumRelativeValue = @(-10);
        verticalMotionEffect.maximumRelativeValue = @(10);
        
        // Set horizontal effect 
        UIInterpolatingMotionEffect *horizontalMotionEffect
            = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
            type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
        horizontalMotionEffect.minimumRelativeValue = @(-10);
        horizontalMotionEffect.maximumRelativeValue = @(10);
        
        // Create group to combine both
        UIMotionEffectGroup *group = [UIMotionEffectGroup new];
        group.motionEffects = @[horizontalMotionEffect, verticalMotionEffect];
        
        // Add both effects to your view
        [self.scrollView addMotionEffect:group];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Show loading indicator
    [self displayLoadingIndicator:true];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Action Handlers

/** @brief Image tapped */
- (void)imageTapped:(UITapGestureRecognizer *)gesture
{
}


#pragma mark - Delegates
#pragma mark - UIScrollViewDelegate

/** @brief For zooming */
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}


@end
