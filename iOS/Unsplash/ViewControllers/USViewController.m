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

    #define URL_UNSPLASH @"http://unsplash.com"

@interface USViewController () <
    UIScrollViewDelegate
>

    /** Main scrolling element */
    @property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

    /** Array to keep track of images loaded */
    @property (strong, nonatomic) NSMutableArray *imageViews;

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
    self.imageViews = [NSMutableArray new];

    // Notification observer
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(imageURLsFetched:)
        name:NOTIFICATION_IMAGE_URL_CACHE_UPDATED
        object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(imageLoaded:)
        name:NOTIFICATION_IMAGE_LOADED
        object:nil];

    // Setup datasource - use Tumblr API instead
//    USWebViewController *webVC = [[USWebViewController alloc] initWithURLString:URL_UNSPLASH];
    self.datasource = [[USImageDatasource alloc] initWithURLString:URL_UNSPLASH];

    // Setup Scrollview
    self.scrollView.backgroundColor = [UIColor darkGrayColor];
    self.scrollView.delegate = self;
    self.scrollView.pagingEnabled = true;
    self.scrollView.directionalLockEnabled = true;
    self.scrollView.showsVerticalScrollIndicator = false;
    self.scrollView.showsHorizontalScrollIndicator = true;
    [self.scrollView addObserver:self forKeyPath:@"contentSize"
        options:kNilOptions context:nil];   // For clean rotations
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    debugLog(@"viewWillAppear");

    // Get images if on first page
    if (self.datasource && !self.lastShownPage) {
        [self.datasource fetchMoreImages];
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // Reposition images
    [self updateScrollView:self.scrollView.bounds];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
    return YES; // Hide status bar
}


#pragma mark - Setup

/** @brief Add parallax effects */
- (void)addParallaxToView:(UIView *)view
{
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
        [view addMotionEffect:group];
    }
}


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
    debugLog(@"updateScrollView");

    // Update scrollview content size based on number of imageurls
    NSArray *imageURLs = self.datasource.imageURLCache;
    self.scrollView.contentSize = CGSizeMake(
        CGRectGetWidth(bounds) * ([imageURLs count] + 1),   // +1 for intro
        CGRectGetHeight(bounds)
    );

    // Reposition existing images
    for (NSInteger i = 0; i < self.imageViews.count; ++i)
    {
        [self.imageViews[i] setFrame:CGRectMake(
            (i + 1) * CGRectGetWidth(bounds), 0,
            CGRectGetWidth(bounds), CGRectGetHeight(bounds)
        )];
    }

    // Add new placeholder images
    for (NSInteger i = self.imageViews.count; i < imageURLs.count; ++i)
    {
        // Create loading indicator
        UIActivityIndicatorView *loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        loadingView.frame = CGRectMake(
            (i + 1) * CGRectGetWidth(bounds), 0,
            CGRectGetWidth(bounds), CGRectGetHeight(bounds)
        );
        [self.scrollView addSubview:loadingView];

        // Keep track of it
        [self.imageViews addObject:loadingView];
    }
}


#pragma mark - Event Handlers

/** @brief When screen is tapped */
- (void)screenTapped:(UITapGestureRecognizer *)gesture
{
    debugLog(@"screenTapped");
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
    if (index >= self.imageViews.count) {
        NSLog(@"Index from imageLoaded notification out of bounds!");
        return;
    }

    // Get image view to show
    UIActivityIndicatorView *view = [self.imageViews objectAtIndex:index];

    // Only proceed if view is a loading indicator
    if (!view || ![view isKindOfClass:[UIActivityIndicatorView class]]) {
        return;
    }

    // Fade out view and add image
    __block USViewController *this = self;
    [UIView animateWithDuration:ANIMATION_DURATION_FAST delay:0
        options:UIViewAnimationOptionBeginFromCurrentState
        animations:^{
            view.alpha = 0;
        }
        completion:^(BOOL finished)
        {
            if (this)
            {
                // Add ImageView
                UIImageView *imageView = [[UIImageView alloc] initWithFrame:view.frame];
                imageView.contentMode = UIViewContentModeScaleAspectFill;
                imageView.backgroundColor = [UIColor clearColor];
                imageView.clipsToBounds = true;
                [imageView setImage:[this.datasource.imageCache objectAtIndex:index]];

                // Remove loading indicator
                [view stopAnimating];
                [view removeFromSuperview];

                // Fade in imageview
                imageView.alpha = 0;
                [this.scrollView addSubview:imageView];
                [UIView animateWithDuration:ANIMATION_DURATION_FAST delay:0
                    options:UIViewAnimationOptionBeginFromCurrentState
                    animations:^{
                        imageView.alpha = 1;
                    } completion:nil];
            }
        }];
}

/** @brief When content size is being changed on scrollview */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // Update content offset based on content size for smooth rotation change
    self.scrollView.contentOffset = CGPointMake(
        self.lastShownPage * CGRectGetWidth(self.scrollView.bounds), 0);
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
    NSInteger numImages = [self.datasource.imageURLCache count];
	if (page >= numImages) {
		page = numImages - 1;
	} else if (page < 0) {
		page = 0;
	}

	// If page is not the same as lastShownPage, page is about to change
	if (self.lastShownPage != page)
    {
        debugLog(@"pageChange: %i to %i", self.lastShownPage, page);

        // Update last shown page number
        self.lastShownPage = page;

        // Fetch following images as a buffer
        [self fetchImageAtIndex:page];
        if (page + 1 < numImages) {
            [self fetchImageAtIndex:page + 1];
        }

        // If page number is last page, ask for more images
        if (page == numImages - 1) {
            [self.datasource fetchMoreImages];
        }
	}
}


@end
