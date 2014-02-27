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
    NSLog(@"scrapePageForImages");

    // First set noConflict for jQuery
    [self.webVC executeJS:@"$.noConflict();" completion:nil];

    // Get list of img elements inside list of posts
    [self.webVC executeJS:@"JSON.stringify(jQuery('#posts').find('img').map(function() { return this.src; }).get())" completion:^(NSString *result)
    {
        NSLog(@"Images: %@", result);

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

            // Notify that cache is updated
            [[NSNotificationCenter defaultCenter]
                postNotificationName:NOTIFICATION_IMAGE_URL_CACHE_UPDATED
                object:self userInfo:@{ @"data":self.imageURLCache }];

            // Start downloading images asynchronously
            [self downloadImages];
        }
    }];
}

/** @brief Inject jQuery */
- (void)injectJQueryWithCompletionHandler:(CompletionBlock)completion
{
    NSLog(@"Injecting jQuery");
    [self.webVC injectJSFromURL:[NSURL URLWithString:URL_JQUERY] completion:completion];
}

/** @brief Asynchronously downloading images that aren't cached yet */
- (void)downloadImages
{
    // Only download the ones that aren't in the cache already

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
