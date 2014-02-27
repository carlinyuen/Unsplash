//
//  USImageDatasource.h
//  Unsplash
//
//  Created by . Carlin on 2/27/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "USWebViewController.h"

@interface USImageDatasource : NSObject

    @property (nonatomic, strong) USWebViewController *webVC;

    /** @brief Convenience constructor to pass in webVC */
    - (id)initWithWebView:(USWebViewController *)webVC;

@end
