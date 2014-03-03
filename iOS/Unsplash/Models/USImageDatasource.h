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

    /** Cached array of images and urls */
    @property (nonatomic, strong, readonly) NSMutableArray *imageURLCache;
    @property (nonatomic, strong, readonly) NSMutableArray *imageCache;

    /** @brief Convenience constructor to pass in webVC */
    - (id)initWithWebView:(USWebViewController *)webVC;
    
    /** @brief Asynchronously download image and store into imageCache.
        @param index Index of */
    - (void)downloadImageAtIndex:(NSInteger)index;

    /** @brief Call to request more images from the datasource */
    - (void)fetchMoreImages;

@end
