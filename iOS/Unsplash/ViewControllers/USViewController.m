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

    // Setup datasource
    USWebViewController *webVC = [[USWebViewController alloc] initWithURLString:URL_UNSPLASH];
    self.datasource = [[USImageDatasource alloc] initWithWebView:webVC];
    [self.scrollView addSubview:webVC.view];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
