//
//  USImageDatasource.m
//  Unsplash
//
//  Created by . Carlin on 2/27/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//
//  This class uses the actual Tumblr api to get images

#import "USImageDatasource.h"

#import "Keys.h"

    #define URL_API_TUMBLR_GET_POSTS @"api.tumblr.com/v2/blog/%@/posts/photo?api_key=%@&offset=%@"

@interface USImageDatasource ()

    /** Cached array of image urls */
    @property (nonatomic, strong, readwrite) NSMutableArray *imageURLCache;
    @property (nonatomic, strong, readwrite) NSMutableArray *imageCache;

@end

@implementation USImageDatasource

/** @brief Overridden init */
- (id)init
{
    self = [super init];
    if (self)
    {
        _imageCache = [NSMutableArray new];
        _imageURLCache = [NSMutableArray new];
    }
    return self;
}

- (void)dealloc
{
    [_imageCache removeAllObjects];
    [_imageURLCache removeAllObjects];
}


#pragma mark - Class Methods

/** @brief Asynchronously download image and store into imageCache.
    @param index Index of */
- (void)downloadImageAtIndex:(NSInteger)index
{
    __block USImageDatasource *this = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
    {
        // Download image data
        if (this)
        {
            NSString *urlString = [this.imageURLCache objectAtIndex:index];
            NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
            if (data)
            {
                UIImage *image = [UIImage imageWithData:data];
                if (image) {
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        if (this)
                        {
                            // Replace spot in cache
                            [this.imageCache replaceObjectAtIndex:index withObject:image];
                            
                            // Notify that image was downloaded
                            [[NSNotificationCenter defaultCenter]
                                postNotificationName:NOTIFICATION_IMAGE_LOADED
                                object:self userInfo:@{
                                    @"index" : @(index)
                                }];
                        }
                    });
                } else {
                    NSLog(@"Could not create image from data.");
                }
            } else {
                NSLog(@"Could not download image data from url: %@", urlString);
            }
        }
    });
}

/** @brief Call to request more images from the datasource */
- (void)fetchMoreImages
{
    debugLog(@"fetchMoreImages");

    // TODO: Implementation
}


#pragma mark - Event Handlers



@end
