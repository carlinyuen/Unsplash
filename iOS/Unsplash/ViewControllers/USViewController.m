//
//  USViewController.m
//  Unsplash
//
//  Created by . Carlin on 2/26/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//

#import "USViewController.h"

#import "UIERealTimeBlurView.h"
#import "ParallaxScrollingFramework.h"

#import "USImageDatasource.h"
#import "USImageViewController.h"

    #define URL_UNSPLASH @"http://unsplash.com"

    #define IMG_INTRO_BG @"bg_intro.jpg"

    #define TIME_SCROLLING_BG 30

    #define SIZE_BUFFER 2
    #define SIZE_PARALLAX_MOTION 32

@interface USViewController () <
    UIScrollViewDelegate
>

    /** Labels */
    @property (weak, nonatomic) IBOutlet UILabel *titleLabel;
    @property (weak, nonatomic) IBOutlet UILabel *authorLabel;

    /** Buttons */
    @property (weak, nonatomic) IBOutlet UIButton *menuButton;

    /** Main scrolling element */
    @property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

    /** Array to keep track of images loaded */
    @property (strong, nonatomic) NSMutableArray *imageViews;

    /** Datasource to manage images */
    @property (strong, nonatomic) USImageDatasource *datasource;
    
	/** Keep track of which page you're on */
	@property (nonatomic, assign) NSInteger lastShownPage;

    /** Fancy real-time blur view */
    @property (nonatomic, strong) UIERealTimeBlurView *blurView;
    @property (nonatomic, strong) UIView *introView;

    /** Loading indicator for when datasource gets images */
    @property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
    @property (nonatomic, assign) BOOL initialLoad;

    /** Animator for parallax effects */
//    @property (nonatomic, strong) ParallaxScrollingFramework *animator;

@end

@implementation USViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Init
    self.lastShownPage = 0;
    self.imageViews = [NSMutableArray new];
    self.initialLoad = true;

    // Notification observer
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(imageURLsFetched:)
        name:NOTIFICATION_IMAGE_URL_CACHE_UPDATED
        object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(imageLoaded:)
        name:NOTIFICATION_IMAGE_LOADED
        object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(connectionTimedOut:)
        name:NOTIFICATION_CONNECTION_TIMEOUT
        object:nil];

    // Setup datasource - use Tumblr API instead
//    USWebViewController *webVC = [[USWebViewController alloc] initWithURLString:URL_UNSPLASH];
    self.datasource = [[USImageDatasource alloc] initWithURLString:URL_UNSPLASH];

    // Setup Scrollview
    self.scrollView.backgroundColor = [UIColor blackColor];
    self.scrollView.delegate = self;
    self.scrollView.pagingEnabled = true;
    self.scrollView.directionalLockEnabled = true;
    self.scrollView.showsVerticalScrollIndicator = false;
    self.scrollView.showsHorizontalScrollIndicator = true;
    [self.scrollView addObserver:self forKeyPath:@"contentSize"
        options:kNilOptions context:nil];   // For clean rotations

    // Setup Animator
//    self.animator = [[ParallaxScrollingFramework alloc] initWithScrollView:self.scrollView];

    // Setup labels
    self.titleLabel.alpha = 0;
    self.authorLabel.alpha = 0;
    [self addParallaxToView:self.titleLabel];
    [self addParallaxToView:self.authorLabel];

    // Setup blur view and its background
    self.blurView = [[UIERealTimeBlurView alloc] initWithFrame:self.scrollView.bounds];
    self.introView = [[UIView alloc] initWithFrame:self.scrollView.bounds];
    self.introView.backgroundColor = [UIColor clearColor];
    [self.scrollView addSubview:self.introView];
//    [self.scrollView insertSubview:self.blurView aboveSubview:self.introView];
    [self addScrollingBackground:[UIImage imageNamed:IMG_INTRO_BG] duration:TIME_SCROLLING_BG direction:CGPointMake(1, 0) toView:self.introView];

    // Setup buttons
    [self.menuButton addTarget:self action:@selector(menuButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

    // Loading indicator
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.loadingIndicator.alpha = 0;
    [self.scrollView addSubview:self.loadingIndicator];

    // Setup tap gesture
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(screenTapped:)];
    [self.scrollView addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    debugLog(@"viewWillAppear");

    // Get images if on initial load
    if (self.datasource && self.initialLoad)
    {
        self.loadingIndicator.center = self.view.center;
        [self.loadingIndicator startAnimating];
        [UIView animateWithDuration:ANIMATION_DURATION_SLOW animations:^{
            self.loadingIndicator.alpha = 1;
        }];

        [self.datasource fetchMoreImages];
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // Reposition images
    [self updateScrollView:self.scrollView.bounds];

    // Reposition author label
    self.authorLabel.textAlignment
        = UIInterfaceOrientationIsLandscape(toInterfaceOrientation)
            ? NSTextAlignmentRight : NSTextAlignmentCenter;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.

    // Trim down cache for memory
    [self.datasource trimCacheAroundIndex:self.lastShownPage];
}

- (BOOL)prefersStatusBarHidden {
    return YES; // Hide status bar
}

- (void)dealloc
{
    // Remove observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Setup

/** @brief Add scrolling background image */
- (void)addScrollingBackground:(UIImage *)image duration:(NSTimeInterval)duration direction:(CGPoint)direction toView:(UIView *)container
{
    // Frame the background
    container.clipsToBounds = true;

    // Normalize direction
    debugLog(@"Point: %@", NSStringFromCGPoint(direction));
    CGFloat length = sqrtf(direction.x * direction.x + direction.y * direction.y);
    CGPoint point = CGPointApplyAffineTransform(direction,
        CGAffineTransformMakeScale(1.0f / length, 1.0f / length));
    debugLog(@"Normalized Point: %@", NSStringFromCGPoint(point));

    // Set background image to full size and position accordingly for direction
    UIImageView *iv = [[UIImageView alloc] initWithImage:image];
    iv.contentMode = UIViewContentModeScaleAspectFill;
    CGRect frame = iv.frame;
    frame.origin.x = (point.x < 0) ? -CGRectGetWidth(frame)
        : (point.x == 0 ? 0 : CGRectGetWidth(container.bounds));
    frame.origin.y = (point.y > 0) ? -CGRectGetHeight(frame)
        : (point.y == 0 ? 0 : CGRectGetHeight(container.bounds));
    iv.frame = frame;

    debugLog(@"Original Rect: %@", NSStringFromCGRect(frame));
    CGRect targetFrame = CGRectApplyAffineTransform(frame, CGAffineTransformMakeTranslation(
            -point.x * CGRectGetWidth(frame),
            -point.y * CGRectGetHeight(frame)));
    debugLog(@"Target Rect: %@", NSStringFromCGRect(targetFrame));

    // Animate on repeat
    [container addSubview:iv];
    [UIView animateWithDuration:duration delay:0
        options:UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveLinear
        animations:^{
            iv.frame = targetFrame;
        } completion:^(BOOL finished) {
        }];
}

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
        verticalMotionEffect.minimumRelativeValue = @(-SIZE_PARALLAX_MOTION);
        verticalMotionEffect.maximumRelativeValue = @(SIZE_PARALLAX_MOTION);
        
        // Set horizontal effect 
        UIInterpolatingMotionEffect *horizontalMotionEffect
            = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
            type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
        horizontalMotionEffect.minimumRelativeValue = @(-SIZE_PARALLAX_MOTION);
        horizontalMotionEffect.maximumRelativeValue = @(SIZE_PARALLAX_MOTION);
        
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

    // Reposition blur view
    self.blurView.frame = CGRectMake(
        0, 0, CGRectGetWidth(bounds), CGRectGetHeight(bounds)
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
        UIActivityIndicatorView *loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        loadingView.frame = CGRectMake(
            (i + 1) * CGRectGetWidth(bounds), 0,
            CGRectGetWidth(bounds), CGRectGetHeight(bounds)
        );
        [loadingView startAnimating];
        [self.scrollView addSubview:loadingView];

        // Keep track of it
        [self.imageViews addObject:loadingView];
    }
}

/** @brief Displays splash screen (with title label and stuff) */
- (void)displaySplashScreen:(BOOL)show
{
    [UIView animateWithDuration:ANIMATION_DURATION_FAST delay:0
        options:UIViewAnimationOptionCurveEaseInOut
            | UIViewAnimationOptionBeginFromCurrentState
        animations:^{
            self.titleLabel.alpha = show;
            self.authorLabel.alpha = show;
        } completion:nil];
}


#pragma mark - Event Handlers

/** @brief When screen is tapped */
- (void)screenTapped:(UITapGestureRecognizer *)gesture
{
    debugLog(@"screenTapped");
}

/** @brief When menu button is tapped */
- (void)menuButtonTapped:(UIButton *)button
{
    debugLog(@"menuButtonTapped");
}

/** @brief When blur view is tapped */
- (void)blurViewTapped:(UITapGestureRecognizer *)gesture
{
    debugLog(@"blurViewTapped");
}

/** @brief Connection timed out */
- (void)connectionTimedOut:(NSNotification *)notification
{
    debugLog(@"connectionTimedOut");
}

/** @brief When new image urls are scraped from the page */
- (void)imageURLsFetched:(NSNotification *)notification
{
    // On first load
    if (self.initialLoad)
    {
        self.initialLoad = false;

        // Hide loading indicator, show title
        [UIView animateWithDuration:ANIMATION_DURATION_SLOW delay:0
            options:UIViewAnimationOptionBeginFromCurrentState
                | UIViewAnimationOptionCurveEaseInOut
            animations:^{
                self.loadingIndicator.alpha = 0;
                self.titleLabel.alpha = 1;
                self.authorLabel.alpha = 1;
            } completion:^(BOOL finished) {
                [self.loadingIndicator stopAnimating];
            }];
    }

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
                UIImage *image = [this.datasource.imageCache objectAtIndex:index];

                // Create ImageView
                UIImageView *imageView = [[UIImageView alloc] initWithFrame:view.frame];
                imageView.contentMode = UIViewContentModeScaleAspectFill;
                imageView.backgroundColor = [UIColor clearColor];
                imageView.clipsToBounds = true;
                [imageView setImage:image];

                // Remove loading indicator and replace with imageView
                [view stopAnimating];
                [view removeFromSuperview];
                [this.imageViews replaceObjectAtIndex:index withObject:imageView];

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

        // Actions to take when moving to/from first page
        if (page == 1 && self.lastShownPage == 0) {
            [self displaySplashScreen:false];
        } else if (page == 0 && self.lastShownPage != 0) {
            [self displaySplashScreen:true];
        }

        // Update last shown page number
        self.lastShownPage = page;

        // Fetch following images as a buffer
        for (NSInteger i = 0; i < SIZE_BUFFER; ++i) {
            if (page + i < numImages) {
                [self fetchImageAtIndex:page + i];
            }
        }

        // Ask for more images if we're near the end
        if (page >= numImages - SIZE_BUFFER) {
            [self.datasource fetchMoreImages];
        }
	}
}


@end
