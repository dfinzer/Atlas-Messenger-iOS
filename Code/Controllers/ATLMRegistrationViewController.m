//
//  LSRegistrationViewController.m
//  QRCodeTest
//
//  Created by Kevin Coleman on 2/15/15.
//  Copyright (c) 2015 Layer. All rights reserved.
//

#import "ATLMRegistrationViewController.h"
#import "ATLLogoView.h"
#import <Atlas/Atlas.h>
#import "ATLMLayerClient.h"
#import "ATLMAPIManager.h"
#import "ATLMConstants.h"
#import "ATLMUtilities.h"
#import "SVProgressHUD.h"

#import <Parse/Parse.h>

@interface ATLMRegistrationViewController () <UITextFieldDelegate>

@property (nonatomic) ATLLogoView *logoView;
@property (nonatomic) UITextField *registrationTextField;
@property (nonatomic) NSLayoutConstraint *registrationTextFieldBottomConstraint;

@end

@implementation ATLMRegistrationViewController

CGFloat const ATLMLogoViewBCenterYOffset = 184;
CGFloat const ATLMregistrationTextFieldWidthRatio = 0.8;
CGFloat const ATLMregistrationTextFieldHeight = 60;
CGFloat const ATLMregistrationTextFieldBottomPadding = 20;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.logoView = [[ATLLogoView alloc] init];
    self.logoView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.logoView];
    
    self.registrationTextField = [[UITextField alloc] init];
    self.registrationTextField .translatesAutoresizingMaskIntoConstraints = NO;
    self.registrationTextField .delegate = self;
    self.registrationTextField .placeholder = @"My name is...";
    self.registrationTextField .textAlignment = NSTextAlignmentCenter;
    self.registrationTextField .layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.registrationTextField .layer.borderWidth = 0.5;
    self.registrationTextField .layer.cornerRadius = 2;
    self.registrationTextField.font = [UIFont systemFontOfSize:22];
    self.registrationTextField .returnKeyType = UIReturnKeyGo;
    [self.view addSubview:self.registrationTextField ];
    
    [self configureLayoutConstraints];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.registrationTextField becomeFirstResponder];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGRect rect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.registrationTextFieldBottomConstraint.constant = -rect.size.height - ATLMregistrationTextFieldBottomPadding;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [self.view layoutIfNeeded];
    [UIView commitAnimations];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self registerAndAuthenticateUserWithName:textField.text];
    return YES;
}

- (void)registerAndAuthenticateUserWithNameOld:(NSString *)name
{
    [self.view endEditing:YES];
    
    if (self.applicationController.layerClient.authenticatedUserID) {
        NSLog(@"Layer already authenticated as: %@", self.applicationController.layerClient.authenticatedUserID);
        return;
    }
    
    [SVProgressHUD showWithStatus:@"Authenticating with Layer"];
    NSLog(@"Requesting Authentication Nonce");
    [self.applicationController.layerClient requestAuthenticationNonceWithCompletion:^(NSString *nonce, NSError *error) {
        NSLog(@"Got a nonce %@", nonce);
        if (error) {
            ATLMAlertWithError(error);
            return;
        }
        NSLog(@"Registering user");
        [self.applicationController.APIManager registerUserWithName:name nonce:nonce completion:^(NSString *identityToken, NSError *error) {
            NSLog(@"User registerd and got identity token: %@", identityToken);
            if (error) {
                ATLMAlertWithError(error);
                return;
            }
            NSLog(@"Authenticating Layer");
            if (!identityToken) {
                NSError *error = [NSError errorWithDomain:ATLMErrorDomain code:ATLMInvalidIdentityToken userInfo:@{NSLocalizedDescriptionKey : @"Failed to obtain a valid identity token"}];
                ATLMAlertWithError(error);
                return;
            }
            [self.applicationController.layerClient authenticateWithIdentityToken:identityToken completion:^(NSString *authenticatedUserID, NSError *error) {
                if (error) {
                    ATLMAlertWithError(error);
                    return;
                }
                NSLog(@"Layer authenticated as: %@", authenticatedUserID);
                [SVProgressHUD showSuccessWithStatus:@"Authenticated!"];
            }];
        }];
    }];
}

- (void)registerAndAuthenticateUserWithName:(NSString *)name
{
    [self.applicationController.layerClient requestAuthenticationNonceWithCompletion:^(NSString *nonce, NSError *error) {
        NSLog(@"Authentication nonce %@", nonce);
        
        // Upon reciept of nonce, post to your backend and acquire a Layer identityToken
        if (nonce) {
            PFUser *user = [PFUser currentUser];
            NSString *userID  = user.objectId;
            [PFCloud callFunctionInBackground:@"generateToken"
                               withParameters:@{@"nonce" : nonce,
                                                @"userID" : userID}
                                        block:^(NSString *token, NSError *error) {
                                            if (!error) {
                                                // Send the Identity Token to Layer to authenticate the user
                                                [self.applicationController.layerClient authenticateWithIdentityToken:token completion:^(NSString *authenticatedUserID, NSError *error) {
                                                    if (!error) {
                                                        [[PFUser currentUser] setObject:self.applicationController.layerClient.authenticatedUserID forKey:@"layerId"];
                                                        
                                                        NSLog(@"Parse User authenticated with Layer Identity Token");
                                                    } else{
                                                        NSLog(@"Parse User failed to authenticate with token with error: %@", error);
                                                    }
                                                }];
                                            }
                                            else{
                                                NSLog(@"Parse Cloud function failed to be called to generate token with error: %@", error);
                                            }
                                        }];
        }
    }];
}

- (void)configureLayoutConstraints
{
    // Logo View
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.logoView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.logoView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:-ATLMLogoViewBCenterYOffset]];
    
    // Registration View
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.registrationTextField attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.registrationTextField attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:ATLMregistrationTextFieldWidthRatio constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.registrationTextField attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:ATLMregistrationTextFieldHeight]];
    self.registrationTextFieldBottomConstraint = [NSLayoutConstraint constraintWithItem:self.registrationTextField attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-ATLMregistrationTextFieldBottomPadding];
    [self.view addConstraint:self.registrationTextFieldBottomConstraint];
}

@end