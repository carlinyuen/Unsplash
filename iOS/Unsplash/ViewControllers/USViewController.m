//
//  USViewController.m
//  Unsplash
//
//  Created by . Carlin on 2/26/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//

#import "USViewController.h"

#import "ParallaxScrollingFramework.h"

#import "USImageDatasource.h"
#import "USImageViewController.h"

    #define URL_UNSPLASH @"http://unsplash.com"

    #define IMG_INTRO_BG @"bg_intro.jpg"

    #define TIME_SCROLLING_BG 60
    #define TIME_SHOW_ACTION_FADE_DELAY 2

    #define SIZE_BUFFER 2
    #define SIZE_PARALLAX_DEPTH_TEXT 32
    #define SIZE_PARALLAX_DEPTH_BUTTONS 16

    #define TEXT_AUTHOR @"made by ooomf"
    #define TEXT_ERROR_CONNECTION @"no connection"

@interface USViewController () <
    UIScrollViewDelegate
>

    /** Labels */
    @property (weak, nonatomic) IBOutlet UILabel *titleLabel;
    @property (weak, nonatomic) IBOutlet UILabel *infoLabel;

    /** Buttons */
    @property (weak, nonatomic) IBOutlet UIButton *menuButton;
    @property (weak, nonatomic) IBOutlet UIButton *shareButton;

    /** Main scrolling element */
    @property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

    /** Array to keep track of images loaded */
    @property (strong, nonatomic) NSMutableArray *imageViews;

    /** Datasource to manage images */
    @property (strong, nonatomic) USImageDatasource *datasource;
    
	/** Keep track of which page you're on */
	@property (nonatomic, assign) NSInteger lastShownPage;

    /** Fancy background view */
    @property (nonatomic, strong) UIView *introView;

    /** Loading indicator for when datasource gets images */
    @property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
    @property (nonatomic, assign) BOOL initialLoad;

    /** Timer to keep track of when to fade shown actions */
    @property (nonatomic, strong) NSTimer *fadeActionButtonsTimer;

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
    self.titleLabel.textColor = [UIColor whiteColor];
    self.infoLabel.alpha = 0;
    self.infoLabel.textColor = [UIColor whiteColor];
    [self addParallaxWithDepth:SIZE_PARALLAX_DEPTH_TEXT toView:self.titleLabel];
    [self addParallaxWithDepth:SIZE_PARALLAX_DEPTH_TEXT toView:self.infoLabel];

    // Setup blur view and its background
    self.introView = [[UIView alloc] initWithFrame:self.scrollView.bounds];
    self.introView.backgroundColor = [UIColor clearColor];
    self.introView.alpha = 0;
    [self.scrollView addSubview:self.introView];

    // Setup buttons
    [self.menuButton addTarget:self action:@selector(menuButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.menuButton.alpha = 0;
    [self addParallaxWithDepth:SIZE_PARALLAX_DEPTH_BUTTONS toView:self.menuButton];
    [self.shareButton addTarget:self action:@selector(shareButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.shareButton.alpha = 0;
    [self addParallaxWithDepth:SIZE_PARALLAX_DEPTH_BUTTONS toView:self.shareButton];

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

    // Get images if on initial load and haven't loaded yet
    if (self.datasource && self.initialLoad)
    {
        self.loadingIndicator.center = self.view.center;
        [self.loadingIndicator startAnimating];
        [UIView animateWithDuration:ANIMATION_DURATION_SLOW delay:0
            options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState
            animations:^{
                self.loadingIndicator.alpha = 1;
                self.infoLabel.alpha = 0;   // Hide errors that were shown before
            } completion:nil];

        [self.datasource fetchMoreImages];
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // Reposition images
    [self updateScrollView:self.scrollView.bounds];

    // Reposition author label
    self.infoLabel.textAlignment
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
    CGFloat length = sqrtf(direction.x * direction.x + direction.y * direction.y);
    CGPoint point = CGPointApplyAffineTransform(direction,
        CGAffineTransformMakeScale(1.0f / length, 1.0f / length));

    // Set background image to full size and position accordingly for direction
    UIImageView *iv = [[UIImageView alloc] initWithImage:image];
    iv.contentMode = UIViewContentModeScaleAspectFill;
    CGRect frame = iv.frame;
    frame.origin.x = (point.x < 0) ? -CGRectGetWidth(frame) : 0;
    frame.origin.y = (point.y > 0) ? -CGRectGetHeight(frame) : 0;
    iv.frame = frame;

    // Calculate target frame
    CGRect targetFrame = CGRectApplyAffineTransform(frame, CGAffineTransformMakeTranslation(
            -(point.x * CGRectGetWidth(frame) - point.x * CGRectGetWidth(container.bounds)),
            -(point.y * CGRectGetHeight(frame) - point.y * CGRectGetHeight(container.bounds))
        ));

    // Animate on repeat
    [container addSubview:iv];
    [UIView animateWithDuration:duration delay:0
        options:UIViewAnimationOptionRepeat
            | UIViewAnimationOptionCurveLinear
            | UIViewAnimationOptionAutoreverse
        animations:^{
            iv.frame = targetFrame;
        } completion:^(BOOL finished) {
        }];
}

/** @brief Add parallax effects */
- (void)addParallaxWithDepth:(CGFloat)depth toView:(UIView *)view
{
    // Adding parallax effect for iOS 7
    if (!deviceOSVersionLessThan(iOS7))
    {
        // Set vertical effect
        UIInterpolatingMotionEffect *verticalMotionEffect
            = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
            type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
        verticalMotionEffect.minimumRelativeValue = @(-depth);
        verticalMotionEffect.maximumRelativeValue = @(depth);
        
        // Set horizontal effect 
        UIInterpolatingMotionEffect *horizontalMotionEffect
            = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
            type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
        horizontalMotionEffect.minimumRelativeValue = @(-depth);
        horizontalMotionEffect.maximumRelativeValue = @(depth);
        
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

    // Reposition intro screen view
    self.introView.frame = CGRectMake(
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
    __block USViewController *this = self;
    [UIView animateWithDuration:ANIMATION_DURATION_FAST delay:0
        options:UIViewAnimationOptionCurveEaseInOut
            | UIViewAnimationOptionBeginFromCurrentState
        animations:^{
            [[this titleLabel] setAlpha:show];
            [[this infoLabel] setAlpha:show];
            [[this menuButton] setAlpha:show];
        } completion:nil];
}

/** @brief Displays image action options */
- (void)displayActionButtons:(BOOL)show
{
    // Cancel fade timer if exists
    if (self.fadeActionButtonsTimer) {
        [self.fadeActionButtonsTimer invalidate];
        self.fadeActionButtonsTimer = nil;
    }

    __block USViewController *this = self;
    [UIView animateWithDuration:ANIMATION_DURATION_FAST delay:0
        options:UIViewAnimationOptionCurveEaseInOut
            | UIViewAnimationOptionBeginFromCurrentState
        animations:^{
            [[this menuButton] setAlpha:show];
            [[this shareButton] setAlpha:show];
        } completion:^(BOOL finished) {
            if (finished && show) {
                [this setFadeActionButtonsTimer:[NSTimer scheduledTimerWithTimeInterval:TIME_SHOW_ACTION_FADE_DELAY
                    target:this selector:@selector(fadeActionButtonsTimerTriggered:)
                    userInfo:nil repeats:false]];
            }
        }];
}

/** @brief Displays loading indicator */
- (void)displayLoadingIndicator:(BOOL)show
{
    __block USViewController *this = self;
    if (show) {
        [self.loadingIndicator startAnimating];
    }
    [UIView animateWithDuration:ANIMATION_DURATION_SLOW delay:0
        options:UIViewAnimationOptionBeginFromCurrentState
            | UIViewAnimationOptionCurveEaseInOut
        animations:^{
            [[this loadingIndicator] setAlpha:show];
        } completion:^(BOOL finished) {
            if (finished && !show) {
                [[this loadingIndicator] stopAnimating];
            }
        }];

}


#pragma mark - Event Handlers

/** @brief Action delay timer triggered */
- (void)fadeActionButtonsTimerTriggered:(NSTimer *)timer
{
    [self displayActionButtons:false];
}

/** @brief When screen is tapped */
- (void)screenTapped:(UITapGestureRecognizer *)gesture
{
    debugLog(@"screenTapped");

    // Toggle action buttons if not on first screen
    if (self.lastShownPage > 0) {
        [self displayActionButtons:(self.menuButton.alpha == 0)];
    }
}

/** @brief When menu button is tapped */
- (void)menuButtonTapped:(UIButton *)button
{
    debugLog(@"menuButtonTapped");
}

/** @brief When share button is tapped */
- (void)shareButtonTapped:(UIButton *)button
{
    debugLog(@"shareButtonTapped");

    // Setup ActivityViewController
    NSInteger index = self.lastShownPage;
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[
        [self.datasource.imageCache objectAtIndex:index],       // Image
        [NSURL URLWithString:[self.datasource.imageURLCache objectAtIndex:index]],    // URL
    ] applicationActivities:nil];

    // Show activity sheet
    [self presentViewController:activityVC animated:YES completion:nil];
}

/** @brief Connection timed out */
- (void)connectionTimedOut:(NSNotification *)notification
{
    debugLog(@"connectionTimedOut");

    // Use info label to display connection error
    self.infoLabel.text = TEXT_ERROR_CONNECTION;

    // Animate to show
    [UIView animateWithDuration:ANIMATION_DURATION_FAST delay:0
        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
        animations:^{
            self.infoLabel.alpha = 1;
        } completion:nil];
}

/** @brief When new image urls are scraped from the page */
- (void)imageURLsFetched:(NSNotification *)notification
{
    // On first load
    if (self.initialLoad)
    {
        self.initialLoad = false;

        // Start scrolling background
        [self addScrollingBackground:[UIImage imageNamed:IMG_INTRO_BG] duration:TIME_SCROLLING_BG direction:CGPointMake(1, 0) toView:self.introView];

        // Hide loading indicator, show title and info labels
        self.infoLabel.text = TEXT_AUTHOR;
        __block USViewController *this = self;
        [UIView animateWithDuration:ANIMATION_DURATION_SLOW delay:0
            options:UIViewAnimationOptionBeginFromCurrentState
                | UIViewAnimationOptionCurveEaseInOut
            animations:^{
                [[this loadingIndicator] setAlpha:0];
                [[this titleLabel] setAlpha:1];
                [[this infoLabel] setAlpha:1];
                [[this introView] setAlpha:1];
                [[this menuButton] setAlpha:1];
            } completion:^(BOOL finished) {
                if (finished) {
                    [[this loadingIndicator] stopAnimating];
                }
            }];

        // Cancel any local notifications remaining
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
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
        } else if (page == 0) {     // Show splash screen
            [self displaySplashScreen:true];
        } else {    // Hide action buttons when scrolling
            [self displayActionButtons:false];
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
