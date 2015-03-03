//
//  CHContactUtils.h
//  Hipframe
//
//  Created by Devin on 12/27/13.
//  Copyright (c) 2013 Devin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface THContactUtils : NSObject

// The name to display for a contact.
+ (NSString *)displayStringForContact:(PFObject *)contact;

// The name to display for a user.
+ (NSString *)displayStringForUser:(PFUser *)user;

// The subtitle to display for a contact.
+ (NSString *)subtitleStringForContact:(PFObject *)contact;

// A short name to display for a contact.
+ (NSString *)shortDisplayStringForContact:(PFObject *)contact;

// A short name to display for a user.
+ (NSString *)shortDisplayStringForUser:(PFObject *)user;

+ (NSArray *)contactsSortedByDisplayNames:(NSArray *)contacts;

+ (NSArray *)usersSortedByDisplayNames:(NSArray *)users;

@end
