//
//  USImageViewController.h
//  Unsplash
//
//  Created by . Carlin on 2/26/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "USLoadingViewController.h"

@interface USImageViewController : USLoadingViewController <
    UIScrollViewDelegate
>

    /** Imageview for image */
    @property (weak, nonatomic) IBOutlet UIImageView *imageView;

    /** Scrollview so we can zoom for viewing images */
    @property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end
