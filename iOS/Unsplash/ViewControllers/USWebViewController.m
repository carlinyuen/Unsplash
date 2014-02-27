//
//  USWebViewController.m
//  Unsplash
//
//  Created by . Carlin on 2/27/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//

#import "USWebViewController.h"

    #define URL_JQUERY @"http://ajax.googleapis.com/ajax/libs/jquery/2.1.0/jquery.min.js"

    typedef void(^CompletionBlock)(NSString *result);

@interface USWebViewController () <
    UIWebViewDelegate
>

    /** Webview to load url */
    @property (weak, nonatomic) IBOutlet UIWebView *webView;

    /** Track loads to find out when page is finished loading */
    @property (assign, nonatomic) NSInteger webViewLoads;

    /** Flag to make sure we only inject jQuery once */
    @property (assign, nonatomic) BOOL jQueryInjected;

@end

@implementation USWebViewController

- (id)initWithURLString:(NSString *)urlString
{
    self = [super initWithNibName:@"USWebViewController" bundle:nil];
    if (self) {
        _urlString = urlString;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.jQueryInjected = false;

    self.webView.delegate = self;

    [self reloadWebView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Getter / Setters

- (void)setUrlString:(NSString *)urlString
{
    _urlString = urlString;
    [self reloadWebView];
}


#pragma mark - Class Methods

/** @brief Reload page with url */
- (void)reloadWebView
{
    [self.webView loadRequest:[NSURLRequest
        requestWithURL:[NSURL
            URLWithString:self.urlString]]];
}

/** @brief Inject jQuery */
- (void)injectJQueryWithCompletionHandler:(CompletionBlock)completion
{
    NSLog(@"Injecting jQuery");
    [self injectJSFromURL:[NSURL URLWithString:URL_JQUERY] completion:completion];
}

/** @brief Scrolls to an offset that is normalized to 0-1 in reference to the total width / height of the page */
- (BOOL)scrollToNormalizedOffset:(CGPoint)offset
{
    // Don't scroll if still loading
    if (self.webView.isLoading) {
        return false;
    }

    // Only do height for now
    CGFloat yOffset = offset.y * self.webView.scrollView.contentSize.height;

    // Scroll to point
    [self executeJS:[NSString stringWithFormat:
        @"jQuery('html, body').animate({"
            @"scrollTop: %@"
        @"}, 2000);", @(yOffset)] completion:nil];

    return true;
}

/** @brief Scrolls to element on page */
- (BOOL)scrollToElementId:(NSString *)elementID
{
    // Don't scroll if still loading
    if (self.webView.isLoading) {
        return false;
    }

    // Scroll to point
    [self executeJS:[NSString stringWithFormat:
        @"jQuery('html, body').animate({"
            @"scrollTop: jQuery('#%@').offset().top"
        @"}, 2000);", elementID] completion:nil];

    return true;
}

/** @brief Inject javascript from file into webpage */
- (void)injectJSFromURL:(NSURL *)jsUrl completion:(CompletionBlock)completion
{
    __block USWebViewController *this = self;
    dispatch_async(dispatch_get_global_queue(
        DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
    {
        NSData *jsData = [NSData dataWithContentsOfURL:jsUrl];
        if (jsData && [jsData length]) {
            NSString *jsString = [[NSString alloc]
                initWithData:jsData encoding:NSUTF8StringEncoding];
            if (jsString && [jsString length]) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    if (this) {
                        [this executeJS:jsString completion:completion];
                    }
                });
            } else {
                NSLog(@"Could not parse string from data: %@", jsData);
            }
        } else {
            NSLog(@"Could not retrieve content from URL: %@", jsUrl);
        }
    });
}

/** @brief Executes JS on webpage */
- (void)executeJS:(NSString *)jsString completion:(CompletionBlock)completion
{
    NSLog(@"Executing JS on webview");
    NSString *result = [self.webView stringByEvaluatingJavaScriptFromString:jsString];
    if (!result) {
        NSLog(@"Error from executing js: %@", jsString);
    }
    if (completion) {
        completion(result);
    }
}

/** @brief Scrape page for image elements */
- (void)scrapePageForImages
{
    NSLog(@"scrapePageForImages");

    // First set noConflict for jQuery
    [self executeJS:@"$.noConflict();" completion:nil];

    // Get list of img elements inside list of posts
    [self executeJS:@"JSON.stringify(jQuery('#posts').find('img').map(function() { return this.src; }).get())" completion:^(NSString *result)
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


#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"shouldStartLoadWithRequest: %@", [request URL]);

    // Default to yes
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    NSLog(@"didStartLoad, stillLoading: %@", @(webView.loading));

    self.webViewLoads++;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"didFinishLoad, stillLoading: %@", @(webView.loading));

    self.webViewLoads--;

    // Not done loading yet
    if (self.webViewLoads > 0) {
        return;
    }

    // Inject jQuery so we can use it
    if (!self.jQueryInjected)
    {
        __block USWebViewController *this = self;
        [self injectJQueryWithCompletionHandler:^(NSString *result) {
            if (this) {
                [this scrapePageForImages];
            }
        }];
    } else {
        [self scrapePageForImages];
    }
}

- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error
{
    self.webViewLoads--;
}

@end
