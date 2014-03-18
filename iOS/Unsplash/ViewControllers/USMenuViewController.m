//
//  USMenuViewController.m
//  Unsplashed
//
//  Created by . Carlin on 3/18/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//

#import "USMenuViewController.h"

@interface USMenuViewController ()

    @property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation USMenuViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
