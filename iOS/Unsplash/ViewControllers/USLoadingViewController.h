//
//  USLoadingViewController.h
//  Unsplash
//
//  Created by . Carlin on 2/27/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface USLoadingViewController : UIViewController

    /** Loading indicator */
    @property (strong, nonatomic) UIActivityIndicatorView *loadingIndicator;

    /** @brief Show / hide loading indicator */
    - (void)displayLoadingIndicator:(BOOL)show;

@end
