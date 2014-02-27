//
//  USLoadingViewController.m
//  Unsplash
//
//  Created by . Carlin on 2/27/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//

#import "USLoadingViewController.h"

@implementation USLoadingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Loading indicator
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.loadingIndicator.alpha = 0;
}


#pragma mark - Class Methods

/** @brief Show / hide loading indicator */
- (void)displayLoadingIndicator:(BOOL)show
{
    if (show) {
        [self.loadingIndicator startAnimating];
        [self.view addSubview:self.loadingIndicator];
    }

    __block USLoadingViewController *this = self;
    [UIView animateWithDuration:ANIMATION_DURATION_FAST delay:0
        options:UIViewAnimationOptionBeginFromCurrentState
        animations:^{
            if (this) {
                this.loadingIndicator.alpha = (show ? 1 : 0);
            }
        } completion:^(BOOL finished) {
            if (finished) {
                if (this && !show) {
                    [this.loadingIndicator stopAnimating];
                    [this.loadingIndicator removeFromSuperview];
                }
            }
        }];
}

@end
