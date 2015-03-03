//
//  THComposeViewController.m
//  Thread
//
//  Created by Devin Finzer on 3/1/15.
//  Copyright (c) 2015 Devin Finzer. All rights reserved.
//

#import "THComposeViewController.h"
#import "THCardView.h"
#import "NSMutableDictionary+THAdditions.h"

@interface THComposeViewController ()

@property (nonatomic, strong, readwrite) THCardView *cardView;

@end

@implementation THComposeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect photoViewFrame = CGRectMake(5, 20, 310, 310);
    self.cardView = [[THCardView alloc] initWithFrame:photoViewFrame];
    self.cardView.imageData = @{
                            @"thumbnail_url": @"http://cdn2.blisstree.com/wp-content/uploads/2009/05/hug-your-cat-day.jpg",
                            @"image_url": @"http://cdn2.blisstree.com/wp-content/uploads/2009/05/hug-your-cat-day.jpg"
                            };
    self.cardView.bottomText = @"OH HEY";
    self.cardView.topText = @"OH HAI";
    self.cardView.editable = YES;
    [self.view addSubview:self.cardView];
    
    // Send button.
    UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [sendButton setTitle:@"SEND" forState:UIControlStateNormal];
    [sendButton addTarget:self action:@selector(send) forControlEvents:UIControlEventTouchDown];
    sendButton.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
    [sendButton sizeToFit];
    [self.view addSubview:sendButton];
}

- (void)send
{
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setObject:@"http://cdn2.blisstree.com/wp-content/uploads/2009/05/hug-your-cat-day.jpg" forKey:@"image_url"];
    [data setObject:@"http://cdn2.blisstree.com/wp-content/uploads/2009/05/hug-your-cat-day.jpg" forKey:@"thumbnail_url"];
    [data setObject:self.cardView.bottomText forKey:@"bottom_text"];
    [data setObject:self.cardView.topText forKey:@"top_text"];
    
    [self.delegate composeViewController:self didSendMeem:data];
}

@end
