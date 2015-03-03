//
//  THFacebookUtils.m
//  Thread
//
//  Created by Devin Finzer on 3/1/15.
//  Copyright (c) 2015 Devin Finzer. All rights reserved.
//

#import "THFacebookUtils.h"

#import "NSMutableDictionary+THAdditions.h"

#import <ParseFacebookUtils/PFFacebookUtils.h>

@implementation THFacebookUtils

+ (NSArray *)facebookPermissions
{
    return @[@"user_photos", @"user_friends"];
}

+ (void)setFacebookDataForUser
{
    [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            // Store the current user's Facebook ID on the user
            PFUser *currentUser = [PFUser currentUser];
            
            NSMutableDictionary *facebookData = [NSMutableDictionary dictionary];
            [facebookData setObjectSafe:[result objectForKey:@"id"] forKey:@"fbId"];
            [facebookData setObjectSafe:[result objectForKey:@"email"] forKey:@"email"];
            [facebookData setObjectSafe:[result objectForKey:@"name"] forKey:@"name"];
            [facebookData setObjectSafe:[result objectForKey:@"first_name"] forKey:@"firstName"];
            [facebookData setObjectSafe:[result objectForKey:@"last_name"] forKey:@"lastName"];
            
            [currentUser setValuesForKeysWithDictionary:facebookData];
            [currentUser saveInBackground];
        }
    }];
}

@end
