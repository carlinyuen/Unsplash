//
//  USWebViewController.h
//  Unsplash
//
//  Created by . Carlin on 2/27/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface USWebViewController : UIViewController

    /** URL to load */
    @property (copy, nonatomic) NSString *urlString;

    /** @brief Convenience constructor to start with urlString */
    - (id)initWithURLString:(NSString *)urlString;

@end
