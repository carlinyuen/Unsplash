//
//  USMenuViewController.m
//  Unsplashed
//
//  Created by . Carlin on 3/18/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//

#import "USMenuViewController.h"

#import <MessageUI/MFMailComposeViewController.h>

    #define URL_FORMAT_APP_STORE @"itms-apps://itunes.apple.com/app/id%@?at=10l6dK"
    #define URL_FORMAT_APP_STORE_IOS7 @"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@&at=10l6dK"
    #define ID_APP_STORE 838269515
    #define FEEDBACK_EMAIL @"email.me@carlinyuen.com"

    #define TEXT_FEEDBACK_EMAIL_SUBJECT @"About Unsplashed"
    #define TEXT_FEEDBACK_SENT_TITLE @"Message Sent"
    #define TEXT_FEEDBACK_SENT_MESSAGE @"Thanks for your feedback\nand have a great day! :o)"
    #define TEXT_ERROR_TITLE @"Oops!"
    #define TEXT_ERROR_OPENURL @"It looks like your device can't open this url. Check that you have a web browser enabled."

@interface USMenuViewController () <
    MFMailComposeViewControllerDelegate
>

    @property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

    - (IBAction)rateButtonTapped:(id)sender;
    - (IBAction)feedbackButtonTapped:(id)sender;
    - (IBAction)jumpToBeginningButtonTapped:(id)sender;

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


#pragma mark - Event Handlers

- (IBAction)rateButtonTapped:(id)sender
{
    NSURL *url = [NSURL URLWithString:[NSString
        stringWithFormat:(deviceOSVersionLessThan(iOS7)
            ? URL_FORMAT_APP_STORE : URL_FORMAT_APP_STORE_IOS7),
                @(ID_APP_STORE)
    ]];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    } else {
        [[[UIAlertView alloc]
            initWithTitle:TEXT_ERROR_TITLE
            message:TEXT_ERROR_OPENURL
            delegate:nil
            cancelButtonTitle:@"Ok"
            otherButtonTitles:nil] show];
    }
}

/** Feedback button tapped */
- (IBAction)feedbackButtonTapped:(id)sender
{
    // Send out message to email
    MFMailComposeViewController* mailController = [MFMailComposeViewController new];
    mailController.mailComposeDelegate = self;
    [mailController setSubject:TEXT_FEEDBACK_EMAIL_SUBJECT];
    [mailController setToRecipients:@[FEEDBACK_EMAIL]];
    [self presentViewController:mailController animated:true completion:nil];
}

- (IBAction)jumpToBeginningButtonTapped:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(menuVC:jumpToBeginning:)]) {
        [self.delegate menuVC:self jumpToBeginning:sender];
    }
}


#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller  
          didFinishWithResult:(MFMailComposeResult)result 
                        error:(NSError*)error;
{
    [self dismissViewControllerAnimated:true completion:^{
        if (result == MFMailComposeResultSent) {
            [[[UIAlertView alloc]
                initWithTitle:TEXT_FEEDBACK_SENT_TITLE
                message:TEXT_FEEDBACK_SENT_MESSAGE
                delegate:nil
                cancelButtonTitle:@"Ok"
                otherButtonTitles:nil] show];
        }
    }];
}

@end
