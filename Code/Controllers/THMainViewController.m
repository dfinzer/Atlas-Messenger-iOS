//
//  THMainViewController.m
//  Thread
//
//  Created by Devin Finzer on 3/1/15.
//  Copyright (c) 2015 Devin Finzer. All rights reserved.
//

#import "THMainViewController.h"
#import "THComposeViewController.h"
#import "THFacebookUtils.h"
#import "THLogInViewController.h"
#import "ATLMRegistrationViewController.h"

#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>

@interface THMainViewController () <PFLogInViewControllerDelegate>

@end

@implementation THMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    // If the user isn't logged in, show log in view controller.
    if (![PFUser currentUser]) {
        THLogInViewController *logInViewController = [[THLogInViewController alloc] init];
        logInViewController.delegate = self;
        logInViewController.facebookPermissions = [THFacebookUtils facebookPermissions];
        logInViewController.fields = PFLogInFieldsFacebook | PFLogInFieldsDismissButton;
        
        [self presentViewController:logInViewController animated:NO completion:^{}];
        return;
    }
    
    ATLMRegistrationViewController *controller = [[ATLMRegistrationViewController alloc] init];
    controller.applicationController = self.applicationController;
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - PFLoginViewControllerDelegate

- (BOOL)logInViewController:(PFLogInViewController *)logInController
shouldBeginLogInWithUsername:(NSString *)username
                   password:(NSString *)password
{
    return YES;
}

- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error
{
    
}

- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user
{
    [THFacebookUtils setFacebookDataForUser];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController
{
    
}

@end
