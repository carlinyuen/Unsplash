//
//  USMenuViewController.m
//  Unsplashed
//
//  Created by . Carlin on 3/18/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//

#import "USMenuViewController.h"

@interface USMenuViewController ()

    @property (nonatomic, strong) NSMutableArray *info;

@end

@implementation USMenuViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Setup view


    // Setup information data
    self.info = [NSMutableArray new];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Update frame to match
    CGRect frame = self.view.frame;
    frame.size.height = CGRectGetHeight(self.view.superview.bounds);
    self.view.frame = frame;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.info.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    cell.backgroundColor
        = cell.contentView.backgroundColor
        = [UIColor clearColor];

    return cell;
}

@end
