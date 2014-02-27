//
//  USViewController.m
//  Unsplash
//
//  Created by . Carlin on 2/26/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//

#import "USViewController.h"

#import "USWebViewController.h"
#import "USImageDatasource.h"
#import "USImageViewController.h"

    #define URL_UNSPLASH @"http://unsplash.com/"

@interface USViewController ()

    @property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

    @property (strong, nonatomic) USImageDatasource *datasource;

@end

@implementation USViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Notification observer
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(imageURLsFetched:)
        name:NOTIFICATION_IMAGE_URL_CACHE_UPDATED
        object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(imageLoaded:)
        name:NOTIFICATION_IMAGE_LOADED
        object:nil];

    // Setup datasource
    USWebViewController *webVC = [[USWebViewController alloc] initWithURLString:URL_UNSPLASH];
    self.datasource = [[USImageDatasource alloc] initWithWebView:webVC];

    // TODO: Remove at some point
    [self.scrollView addSubview:webVC.view];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Class Methods

/** @brief Update scrollview based on content from datasource */
- (void)updateScrollView
{
    // Update scrollview content size based on number of imageurls
    NSArray *imageURLs = self.datasource.imageURLCache;
    CGRect bounds = self.scrollView.bounds;
    self.scrollView.contentSize = CGSizeMake(
        CGRectGetWidth(bounds) * ([imageURLs count] + 1),   // +1 for intro
        CGRectGetHeight(bounds)
    );
}


#pragma mark - Event Handlers

/** @brief When new image urls are scraped from the page */
- (void)imageURLsFetched:(NSNotification *)notification
{
    [self updateScrollView];
}

/** @brief When new image has been loaded */
- (void)imageLoaded:(NSNotification *)notification
{
    // TODO: Update view at index
}


@end
