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

@interface USViewController () <
    UIScrollViewDelegate
>

    /** Main scrolling element */
    @property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

    /** Array to keep track of images loaded */
    @property (strong, nonatomic) NSMutableArray *imageButtons;

    /** Datasource to manage images */
    @property (strong, nonatomic) USImageDatasource *datasource;
    
	/** Keep track of which page you're on */
	@property (nonatomic, assign) NSInteger lastShownPage;

@end

@implementation USViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Init
    self.lastShownPage = 0;
    self.imageButtons = [NSMutableArray new];

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

    // Setup Scrollview
    self.scrollView.backgroundColor = [UIColor darkGrayColor];
    self.scrollView.delegate = self;
    self.scrollView.pagingEnabled = true;
    self.scrollView.directionalLockEnabled = true;
    self.scrollView.showsVerticalScrollIndicator = false;
    self.scrollView.showsHorizontalScrollIndicator = true;
    [self.scrollView addSubview:webVC.view]; // TODO: Remove at some point

    // Adding parallax effect for iOS 7
    if (!deviceOSVersionLessThan(iOS7))
    {
        // Set vertical effect
        UIInterpolatingMotionEffect *verticalMotionEffect
            = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
            type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
        verticalMotionEffect.minimumRelativeValue = @(-10);
        verticalMotionEffect.maximumRelativeValue = @(10);
        
        // Set horizontal effect 
        UIInterpolatingMotionEffect *horizontalMotionEffect
            = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
            type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
        horizontalMotionEffect.minimumRelativeValue = @(-10);
        horizontalMotionEffect.maximumRelativeValue = @(10);
        
        // Create group to combine both
        UIMotionEffectGroup *group = [UIMotionEffectGroup new];
        group.motionEffects = @[horizontalMotionEffect, verticalMotionEffect];
        
        // Add both effects to your view
        [self.scrollView addMotionEffect:group];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Setup


#pragma mark - Class Methods

/** @brief Fetches the image at index if it isn't already cached */
- (void)fetchImageAtIndex:(NSInteger)index
{
    debugLog(@"fetchImageAtIndex: %i", index);

    UIImage *image = [self.datasource.imageCache objectAtIndex:index];
    if (!image || [image isEqual:[NSNull null]]) {
        [self.datasource downloadImageAtIndex:index];
    }
}

/** @brief Update scrollview based on content from datasource */
- (void)updateScrollView:(CGRect)bounds
{
    // Update scrollview content size based on number of imageurls
    NSArray *imageURLs = self.datasource.imageURLCache;
    self.scrollView.contentSize = CGSizeMake(
        CGRectGetWidth(bounds) * ([imageURLs count] + 1),   // +1 for intro
        CGRectGetHeight(bounds)
    );

    // Reposition existing images
    for (NSInteger i = 0; i < self.imageButtons.count; ++i)
    {
        [self.imageButtons[i] setFrame:CGRectMake(
            (i + 1) * CGRectGetWidth(bounds), 0,
            CGRectGetWidth(bounds), CGRectGetHeight(bounds)
        )];
    }

    // Add new placeholder images
    for (NSInteger i = self.imageButtons.count; i < imageURLs.count; ++i)
    {
        // Create button for it
        UIButton *button = [UIButton new];
        button.frame = CGRectMake(
            (i + 1) * CGRectGetWidth(bounds), 0,
            CGRectGetWidth(bounds), CGRectGetHeight(bounds)
        );
        button.imageView.contentMode = UIViewContentModeScaleAspectFill;
        [button addTarget:self action:@selector(imageButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:button];

        // Keep track of it
        [self.imageButtons addObject:button];
    }
}


#pragma mark - Event Handlers

/** @brief When image button tapped */
- (void)imageButtonTapped:(UIButton *)button
{
    debugLog(@"imageButtonTapped");
}

/** @brief When new image urls are scraped from the page */
- (void)imageURLsFetched:(NSNotification *)notification
{
    // Resize scrollview contentsize
    [self updateScrollView:self.scrollView.bounds];

    // Get first image
    [self fetchImageAtIndex:0];
}

/** @brief When new image has been loaded */
- (void)imageLoaded:(NSNotification *)notification
{
    NSInteger index = [notification.userInfo[@"index"] integerValue];
    debugLog(@"imageLoaded: %i", index);
    if (index >= self.imageButtons.count) {
        NSLog(@"Index from imageLoaded notification out of bounds!");
        return;
    }

    // Get image button to show
    UIButton *imageButton = [self.imageButtons objectAtIndex:index];

    // Fade out button and add image
    [UIView animateWithDuration:ANIMATION_DURATION_FAST delay:0
        options:UIViewAnimationOptionBeginFromCurrentState
        animations:^{
            imageButton.alpha = 0;
        }
        completion:^(BOOL finished) {
            [imageButton setImage:[self.datasource.imageCache objectAtIndex:index] forState:UIControlStateNormal];
            [UIView animateWithDuration:ANIMATION_DURATION_FAST delay:0
                options:UIViewAnimationOptionBeginFromCurrentState
                animations:^{
                    imageButton.alpha = 1;
                } completion:nil];
        }];
}


#pragma mark - Protocols
#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	// Change page control accordingly:
	//	Update the page when more than 50% of the previous/next page is visible
    CGFloat pageSize = CGRectGetWidth(scrollView.bounds);
    int page = floor((scrollView.contentOffset.x - pageSize / 2) / pageSize) + 1;

	// Bound page limits
	if (page >= self.datasource.imageURLCache.count) {
		page = self.datasource.imageURLCache.count - 1;
	} else if (page < 0) {
		page = 0;
	}

	// If page is not the same as lastShownPage, page is about to change
	if (self.lastShownPage != page)
    {
        // If image cache doesn't have next image, start loading it
        [self fetchImageAtIndex:page];

        self.lastShownPage = page;
	}
}


@end
