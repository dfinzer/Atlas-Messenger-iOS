//
//  THFacebookUtils.h
//  Thread
//
//  Created by Devin Finzer on 3/1/15.
//  Copyright (c) 2015 Devin Finzer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface THFacebookUtils : NSObject

+ (NSArray *)facebookPermissions;
+ (void)setFacebookDataForUser;

@end
