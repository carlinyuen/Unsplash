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

    /** Flag to make sure we only inject jQuery once */
    @property (assign, nonatomic) BOOL jQueryInjected;

@end

@implementation USImageDatasource

/** @brief Convenience constructor to pass in webVC */
- (id)initWithWebView:(USWebViewController *)webVC
{
    self = [super init];
    if (self)
    {
        _jQueryInjected = false;

        _webVC = webVC;

        // Add notification observers
        [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(pageLoaded:)
            name:NOTIFICATION_PAGE_LOADED
            object:nil];
    }
    return self;
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
        NSArray *images = [NSJSONSerialization JSONObjectWithData:[result
                dataUsingEncoding:NSUTF8StringEncoding]
            options:kNilOptions error:&error];
        if (error) {
            NSLog(@"Error parsing json: %@", result);
            return;
        }

        // If we have images, store in "cache"
        if (images && [images count]) {

        }
    }];
}

/** @brief Inject jQuery */
- (void)injectJQueryWithCompletionHandler:(CompletionBlock)completion
{
    NSLog(@"Injecting jQuery");
    [self.webVC injectJSFromURL:[NSURL URLWithString:URL_JQUERY] completion:completion];
}


#pragma mark - Event Handlers

/** @brief When we get the page loaded notification */
- (void)pageLoaded:(NSNotification *)notification
{
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
