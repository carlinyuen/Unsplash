//
//  USWebViewController.h
//  Unsplash
//
//  Created by . Carlin on 2/27/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "USLoadingViewController.h"

    typedef void(^CompletionBlock)(NSString *result);

@interface USWebViewController : USLoadingViewController

    /** URL to load */
    @property (copy, nonatomic) NSString *urlString;

    /** @brief Convenience constructor to start with urlString */
    - (id)initWithURLString:(NSString *)urlString;

    /** @brief Inject javascript from file into webpage */
    - (void)injectJSFromURL:(NSURL *)jsUrl completion:(CompletionBlock)completion;

    /** @brief Executes JS on webpage */
    - (void)executeJS:(NSString *)jsString completion:(CompletionBlock)completion;

    /** @brief Scrolls to an offset that is normalized to 0-1 in reference to the total width / height of the page */
    - (BOOL)scrollToNormalizedOffset:(CGPoint)offset;

    /** @brief Scrolls to element on page */
    - (BOOL)scrollToElementId:(NSString *)elementID;

@end
