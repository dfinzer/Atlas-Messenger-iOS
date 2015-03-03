//
//  CHContactUtils.m
//  Hipframe
//
//  Created by Devin on 12/27/13.
//  Copyright (c) 2013 Devin. All rights reserved.
//

#import "THContactUtils.h"

@implementation THContactUtils

+ (NSArray *)contactsSortedByDisplayNames:(NSArray *)contacts
{
    return [contacts sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *obj1String = [THContactUtils displayStringForContact:obj1];
        NSString *obj2String = [THContactUtils displayStringForContact:obj2];
        return [obj1String compare:obj2String options:NSCaseInsensitiveSearch];
    }];
}

+ (NSArray *)usersSortedByDisplayNames:(NSArray *)users
{
    return [users sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *obj1String = [THContactUtils displayStringForUser:obj1];
        NSString *obj2String = [THContactUtils displayStringForUser:obj2];
        return [obj1String compare:obj2String options:NSCaseInsensitiveSearch];
    }];
}

+ (NSString *)displayStringForContact:(PFObject *)contact
{
    PFUser *user = [contact objectForKey:@"toUser"];
    
    NSString *displayString = [contact objectForKey:@"name"];
    if (!displayString) {
        displayString = [THContactUtils displayStringForUser:user];
    }
    return displayString;
}

+ (NSString *)displayStringForUser:(PFUser *)user
{
    NSString *displayString = [user objectForKey:@"name"];
    
    if (!displayString) {
        displayString = [user objectForKey:@"username"];
    }
    return displayString;
}

+ (NSString *)subtitleStringForContact:(PFObject *)contact
{
    NSString *subtitleString = @"";
    subtitleString = [[contact objectForKey:@"toUser"] objectForKey:@"username"];
    if ([subtitleString isEqualToString:[THContactUtils displayStringForContact:contact]]) {
        subtitleString = nil;
    }
    return subtitleString;
}

+ (NSString *)shortDisplayStringForContact:(PFObject *)contact
{
    PFObject *user = [contact objectForKey:@"toUser"];
    NSString *displayString = nil;
    
    if (user) {
        displayString = [self shortDisplayStringForUser:user];
    }
    
    if (!displayString) {
        displayString = [contact objectForKey:@"firstName"];
    }
    
    if (!displayString) {
        displayString = [contact objectForKey:@"name"];
    }
    return displayString;
}

+ (NSString *)shortDisplayStringForUser:(PFObject *)user
{
    NSString *displayString;
    displayString = [user objectForKey:@"firstName"];
    
    if (!displayString) {
        displayString = [user objectForKey:@"username"];
    }
    
    return displayString;
}

@end
