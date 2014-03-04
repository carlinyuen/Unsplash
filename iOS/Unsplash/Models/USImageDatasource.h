//
//  USImageDatasource.h
//  Unsplash
//
//  Created by . Carlin on 2/27/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//
//  This class uses the actual Tumblr api to get images

#import <Foundation/Foundation.h>

    #define KEY_CONNECTION_DOWNLOAD_INDEX @"index"
    #define KEY_CONNECTION_DOWNLOAD_PROGRESS @"progress"
    
@interface USImageDatasource : NSObject

    /** Tumblr blog to pull posts from */
    @property (copy, nonatomic) NSString *blogURLString;

    /** Cached array of images and urls */
    @property (nonatomic, strong, readonly) NSMutableArray *imageURLCache;
    @property (nonatomic, strong, readonly) NSMutableArray *imageCache;

    /** @brief Convenience constructor for urlString */
    - (id)initWithURLString:(NSString *)urlString;

    /** @brief Asynchronously download image and store into imageCache.
        @param index Index of */
    - (void)downloadImageAtIndex:(NSInteger)index;

    /** @brief Call to request more images from the datasource */
    - (void)fetchMoreImages;

    /** @brief Trims down cache to save on memory */
    - (void)trimCacheAroundIndex:(NSInteger)index;

@end
