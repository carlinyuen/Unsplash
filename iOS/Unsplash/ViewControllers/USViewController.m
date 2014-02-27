//
//  USViewController.m
//  Unsplash
//
//  Created by . Carlin on 2/26/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//

#import "USViewController.h"

#import "USWebViewController.h"
#import "USImageViewController.h"

    #define URL_UNSPLASH @"http://unsplash.com/"

@interface USViewController ()

    @property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

    @property (strong, nonatomic) USWebViewController *webVC;

@end

@implementation USViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Setup webview
    self.webVC = [[USWebViewController alloc] initWithURLString:URL_UNSPLASH];
    [self.scrollView addSubview:self.webVC.view];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
