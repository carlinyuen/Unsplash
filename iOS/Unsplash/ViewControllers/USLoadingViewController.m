//
//  USLoadingViewController.m
//  Unsplash
//
//  Created by . Carlin on 2/27/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//

#import "USLoadingViewController.h"

@interface USLoadingViewController ()

@end

@implementation USLoadingViewController

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

    // Loading indicator
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.loadingIndicator.alpha = 0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Class Methods

/** @brief Show / hide loading indicator */
- (void)displayLoadingIndicator:(BOOL)show
{
    if (show) {
        [self.loadingIndicator startAnimating];
        [self.view addSubview:self.loadingIndicator];
    }
    [UIView animateWithDuration:ANIMATION_DURATION_FAST delay:0
        options:UIViewAnimationOptionBeginFromCurrentState
        animations:^{
            self.loadingIndicator.alpha = (show ? 1 : 0);
        } completion:^(BOOL finished) {
            if (finished) {
                if (!show) {
                    [self.loadingIndicator stopAnimating];
                    [self.loadingIndicator removeFromSuperview];
                }
            }
        }];
}

@end
