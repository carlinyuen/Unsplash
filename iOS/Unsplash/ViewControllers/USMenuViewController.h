//
//  USMenuViewController.h
//  Unsplashed
//
//  Created by . Carlin on 3/18/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

@class USMenuViewController;
@protocol USMenuViewControllerDelegate <NSObject>

    @optional
    - (void)menuVC:(USMenuViewController *)vc jumpToFirstButtonTapped:(UIButton *)sender;

@end

@interface USMenuViewController : UIViewController

    @property (weak, nonatomic) id<USMenuViewControllerDelegate> delegate;

@end
