//
//  USWebViewController.m
//  Unsplash
//
//  Created by . Carlin on 2/27/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//

#import "USWebViewController.h"

@interface USWebViewController () <
    UIWebViewDelegate
>

    /** Webview to load url */
    @property (weak, nonatomic) IBOutlet UIWebView *webView;

    /** Track loads to find out when page is finished loading */
    @property (assign, nonatomic) NSInteger webViewLoads;

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

    // Finished loading spree, notify anyone waiting for it
    [[NSNotificationCenter defaultCenter]
        postNotificationName:NOTIFICATION_PAGE_LOADED
        object:self userInfo:nil];

}

- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error
{
    self.webViewLoads--;
}

@end
