//
//  THComposeViewController.h
//  Thread
//
//  Created by Devin Finzer on 3/1/15.
//  Copyright (c) 2015 Devin Finzer. All rights reserved.
//

#import <UIKit/UIKit.h>

@class THComposeViewController;

@protocol THComposeViewControllerDelegate <NSObject>

- (void)composeViewController:(THComposeViewController *)composeViewController didSendMeem:(NSDictionary *)meem;

@end

@interface THComposeViewController : UIViewController

@property (nonatomic, weak) NSObject<THComposeViewControllerDelegate> *delegate;

@end
