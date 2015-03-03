//
//  THComposeViewController.m
//  Thread
//
//  Created by Devin Finzer on 3/1/15.
//  Copyright (c) 2015 Devin Finzer. All rights reserved.
//

#import "THComposeViewController.h"
#import "THCardView.h"

@interface THComposeViewController ()

@end

@implementation THComposeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect photoViewFrame = CGRectMake(5, 20, 310, 310);
    THCardView *photoView = [[THCardView alloc] initWithFrame:photoViewFrame];
    photoView.imageData = @{
                            @"thumbnail_url": @"http://cdn2.blisstree.com/wp-content/uploads/2009/05/hug-your-cat-day.jpg",
                            @"image_url": @"http://cdn2.blisstree.com/wp-content/uploads/2009/05/hug-your-cat-day.jpg"
                            };
    photoView.bottomText = @"OH HEY";
    photoView.topText = @"OH HAI";
    photoView.editable = YES;
    [self.view addSubview:photoView];
    
    // Send button.
    UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [sendButton setTitle:@"LOGOUT" forState:UIControlStateNormal];
    [sendButton addTarget:self action:@selector(logout) forControlEvents:UIControlEventTouchDown];
    sendButton.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
    [sendButton sizeToFit];
    [self.view addSubview:sendButton];
}

@end
