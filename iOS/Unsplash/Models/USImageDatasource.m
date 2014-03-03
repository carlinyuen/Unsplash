//
//  USImageDatasource.m
//  Unsplash
//
//  Created by . Carlin on 2/27/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//

#import "USImageDatasource.h"

    #define URL_JQUERY @"http://ajax.googleapis.com/ajax/libs/jquery/2.1.0/jquery.min.js"

@interface USImageDatasource ()

    /** Cached array of image urls */
    @property (nonatomic, strong, readwrite) NSMutableArray *imageURLCache;
    @property (nonatomic, strong, readwrite) NSMutableArray *imageCache;

    /** Webview that we're using as datasource */
    @property (nonatomic, strong) USWebViewController *webVC;

    /** Flag to make sure we only inject jQuery once */
    @property (assign, nonatomic) BOOL jQueryInjected;

@end

@implementation USImageDatasource

/** @brief Convenience constructor to pass in webVC */
- (id)initWithWebView:(USWebViewController *)webVC
{
    self = [self init];
    if (self)
    {
        _webVC = webVC;
    }
    return self;
}

/** @brief Overridden init */
- (id)init
{
    self = [super init];
    if (self)
    {
        _jQueryInjected = false;

        _imageCache = [NSMutableArray new];
        _imageURLCache = [NSMutableArray new];

        // Add notification observers
        [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(pageLoaded:)
            name:NOTIFICATION_PAGE_LOADED
            object:nil];
    }
    return self;
}

- (void)dealloc
{
    [_imageCache removeAllObjects];
    [_imageURLCache removeAllObjects];
}


#pragma mark - Class Methods

/** @brief Scrape page for image elements */
- (void)scrapePageForImages
{
    debugLog(@"scrapePageForImages");

    // First set noConflict for jQuery
    [self.webVC executeJS:@"$.noConflict();" completion:nil];

    // Get list of img elements inside list of posts
    [self.webVC executeJS:@"JSON.stringify(jQuery('#posts').find('img').map(function() { return this.src; }).get())" completion:^(NSString *result)
    {
        debugLog(@"Images: %@", result);

        // Parse json into array
        NSError *error;
        NSArray *imageURLs = [NSJSONSerialization JSONObjectWithData:[result
                dataUsingEncoding:NSUTF8StringEncoding]
            options:kNilOptions error:&error];
        if (error) {
            NSLog(@"Error parsing json: %@", result);
            return;
        }

        // If we have images, replace url cache
        if (imageURLs && [imageURLs count])
        {
            // Replace urls in cache
            [self.imageURLCache removeAllObjects];
            [self.imageURLCache addObjectsFromArray:imageURLs];

            // Add NSNulls to fill in image cache if it hasn't downloaded yet
            for (NSInteger i = self.imageCache.count; i < self.imageURLCache.count; ++i) {
                [self.imageCache addObject:[NSNull null]];
            }

            // Notify that cache is updated
            [[NSNotificationCenter defaultCenter]
                postNotificationName:NOTIFICATION_IMAGE_URL_CACHE_UPDATED
                object:self userInfo:nil];
        }
    }];
}

/** @brief Inject jQuery */
- (void)injectJQueryWithCompletionHandler:(CompletionBlock)completion
{
    debugLog(@"Injecting jQuery");
    [self.webVC injectJSFromURL:[NSURL URLWithString:URL_JQUERY] completion:completion];
}

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
    [self.webVC scrollToNormalizedOffset:CGPointMake(0, 1)];
}


#pragma mark - Event Handlers

/** @brief When we get the page loaded notification */
- (void)pageLoaded:(NSNotification *)notification
{
    NSLog(@"pageLoaded: %@", notification.userInfo);

    // Inject jQuery so we can use it
    if (!self.jQueryInjected)
    {
        __block USImageDatasource *this = self;
        [self injectJQueryWithCompletionHandler:^(NSString *result) {
            if (this) {
                this.jQueryInjected = true;
                [this scrapePageForImages];
            }
        }];
    } else {
        [self scrapePageForImages];
    }
}

@end
