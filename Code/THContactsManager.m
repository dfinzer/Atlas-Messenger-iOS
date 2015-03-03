//
//  CHContactsManager.m
//  Hipframe
//
//  Created by Devin on 7/31/13.
//  Copyright (c) 2013 Devin. All rights reserved.
//

#import "THContactsManager.h"
#import <AddressBook/AddressBook.h>
#import "THContactUtils.h"
#import "THDefines.h"

#import <FacebookSDK/FacebookSDK.h>

typedef void (^CallbackBlock)(NSArray *objects, NSError *error);

@implementation THContactsManager

+ (THContactsManager *)instance
{
    static THContactsManager *sharedSingleton;
    
    @synchronized(self) {
        if (!sharedSingleton)
            sharedSingleton = [[THContactsManager alloc] init];
        return sharedSingleton;
    }
}

- (ABAuthorizationStatus)addressBookAccessStatus
{
    return ABAddressBookGetAuthorizationStatus();
}

- (void)clearContacts
{
    self.allContacts = @[];
    self.userContacts = @[];
    self.recentContacts = @[];
    self.facebookContacts = @[];
}

- (void)loadAddressBookContacts
{
    // Create the address book.
    CFErrorRef error;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    
    // Request access to the address book.
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error){
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!granted) {
                return;
            }
            
            // Get all the people in the address book.
            NSMutableArray *people = (__bridge_transfer NSMutableArray *)ABAddressBookCopyArrayOfAllPeople(addressBook);
            
            // Iterate through each entry in the address book.
            NSMutableArray *addressBookContacts = [NSMutableArray array];
            NSMutableArray *facebookAddressBookContacts = [NSMutableArray array];
            for (int i = 0; i < people.count; i++) {
                ABMultiValueRef phoneNumbers = ABRecordCopyValue((__bridge ABRecordRef)[people objectAtIndex:i], kABPersonPhoneProperty);
                NSMutableString* phoneNumberString;
                for (CFIndex i = 0; i < ABMultiValueGetCount(phoneNumbers); i++) {
                    phoneNumberString = (__bridge_transfer NSMutableString*) ABMultiValueCopyValueAtIndex(phoneNumbers, i);
                    break;
                }
                CFRelease(phoneNumbers);
                
                if (phoneNumberString) {
                    // Filter out non-decimals.
                    NSCharacterSet *nonDecimalSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
                    phoneNumberString = [[NSMutableString alloc]initWithString:[[phoneNumberString componentsSeparatedByCharactersInSet:nonDecimalSet] componentsJoinedByString:@""]];
                    
                    if (phoneNumberString && ![phoneNumberString isEqualToString:@""]) {
                        // Strip 1 from beginning of phone number string.
                        if ([phoneNumberString characterAtIndex:0] == '1') {
                            NSRange range = {0, 1};
                            [phoneNumberString deleteCharactersInRange:range];
                        }
                        if (phoneNumberString && ![phoneNumberString isEqualToString:@""]) {
                            // Get the name out of the address book.
                            NSString *firstNameString = (__bridge_transfer NSString *)ABRecordCopyValue((__bridge ABRecordRef)([people objectAtIndex:i]), kABPersonFirstNameProperty);
                            NSString *lastNameString = (__bridge_transfer NSString *)ABRecordCopyValue((__bridge ABRecordRef)([people objectAtIndex:i]), kABPersonLastNameProperty);
                            
                            NSString *nameString = @"";
                            
                            // Append first name.
                            if (firstNameString) {
                                nameString = firstNameString;
                            }
                            
                            // Append last name.
                            if (lastNameString) {
                                nameString = [nameString stringByAppendingFormat:@" %@", lastNameString];
                            }
                            
                            // If we don't have a name, this contact isn't really useful.
                            if ([nameString isEqualToString:@""]) {
                                continue;
                            }
                            
                            // Check if this contact exists.
                            if ([PFUser currentUser]) {
                                // If we didn't find one, make a new contact.
                                PFObject *contact = [PFObject objectWithClassName:@"Contact"];
                                [contact setObject:[PFUser currentUser] forKey:@"fromUser"];
                                [contact setObject:nameString forKey:@"name"];
                                [contact setObject:phoneNumberString forKey:@"phone_number"];
                                
                                if (firstNameString) {
                                    [contact setObject:firstNameString forKey:@"firstName"];
                                }
                                
                                if (lastNameString) {
                                    [contact setObject:lastNameString forKey:@"lastName"];
                                }
                                
                                [addressBookContacts addObject:contact];
                            }
                        } 
                    }
                }
                
                ABMultiValueRef profile = ABRecordCopyValue((__bridge ABRecordRef)([people objectAtIndex:i]), kABPersonInstantMessageProperty);
                if (ABMultiValueGetCount(profile) > 0) {
                    for (CFIndex j = 0; j < ABMultiValueGetCount(profile); j++) {
                        NSDictionary *socialItem = (__bridge NSDictionary*)ABMultiValueCopyValueAtIndex(profile, j);
                        NSString* SocialLabel =  [socialItem objectForKey:(NSString *)kABPersonInstantMessageServiceKey];
                        NSString *facebookProfile = ([socialItem objectForKey:(NSString *)kABPersonInstantMessageUsernameKey]);
                        
                        if ([SocialLabel isEqualToString:(NSString *)kABPersonInstantMessageServiceFacebook]) {
                            // Get the name out of the address book.
                            NSString *firstNameString = (__bridge_transfer NSString *)ABRecordCopyValue((__bridge ABRecordRef)([people objectAtIndex:i]), kABPersonFirstNameProperty);
                            NSString *lastNameString = (__bridge_transfer NSString *)ABRecordCopyValue((__bridge ABRecordRef)([people objectAtIndex:i]), kABPersonLastNameProperty);
                            NSString *nameString = @"";
                            NSMutableDictionary *friend = [NSMutableDictionary dictionary];
                            
                            // Append first name.
                            if (firstNameString) {
                                [friend setObject:firstNameString forKey:@"first_name"];
                            }
                            
                            if (lastNameString) {
                                [friend setObject:lastNameString forKey:@"last_name"];
                            }
                            
                            // Append first name.
                            if (firstNameString) {
                                nameString = firstNameString;
                            }
                            
                            // Append last name.
                            if (lastNameString) {
                                nameString = [nameString stringByAppendingFormat:@" %@", lastNameString];
                            }
                            
                            [friend setObject:nameString forKey:@"name"];
                            [friend setObject:facebookProfile forKey:@"facebookID"];
                            
                            NSDictionary *imageData = @{
                                                        @"image": [NSString stringWithFormat:@"http://graph.facebook.com/%@/picture/?width=310&height=310", facebookProfile],
                                                        @"thumbnail": [NSString stringWithFormat:@"http://graph.facebook.com/%@/picture/", facebookProfile],
                                                        @"tag": @"facebook"
                                                        };
                            [friend setObject:imageData forKey:@"image_data"];
                            [facebookAddressBookContacts addObject:friend];
                        }
                        
                    }
                    CFRelease(profile);
                }
            }
            CFRelease(addressBook);
            
            // Add on the contacts.
            self.allContacts = [THContactUtils contactsSortedByDisplayNames:addressBookContacts];
            self.facebookContacts = facebookAddressBookContacts;
            
            // When we reach this point, everything's loaded.
            [self.delegate allContactsDidLoad];
        });
    });
}

- (NSArray *)recentContactsFromUserContacts:(NSArray *)contacts {
    NSInteger maxRecent = 5;
    NSMutableArray *recents = [NSMutableArray array];
    NSInteger numAdded = 0;
    for (PFObject *contact in contacts) {
        BOOL contactExists = [contact objectForKey:@"toUser"] || [contact objectForKey:@"name"];
        if (numAdded < maxRecent && [contact objectForKey:@"lastSend"] && contactExists) {
            [recents addObject:contact];
            numAdded++;
        }
    }
    return [THContactUtils contactsSortedByDisplayNames:recents];
}

- (void)loadAllContacts
{
    // Short circuit if there's no user.
    if (![PFUser currentUser]) {
        return;
    }
    
    [self loadUserContactsWithCallback:^(NSArray *objects, NSError *error) {
        // Update contacts with data from the address book.
        [self loadAddressBookContacts];
    }];
}

- (void)loadUserContacts
{
    [self loadUserContactsWithCallback:^(NSArray *objects, NSError *error) {
        [self.delegate allContactsDidLoad];
    }];
}

// Updates contacts from facebook in the database.
- (void)refreshAndLoadContacts
{
    // Load facebook contacts.
    [FBRequestConnection startForMyFriendsWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error && [PFUser currentUser]) {
            NSArray *friendObjects = [result objectForKey:@"data"];
            NSMutableArray *friendIds = [NSMutableArray arrayWithCapacity:friendObjects.count];
            
            // Create a list of friends' Facebook IDs
            for (NSDictionary *friendObject in friendObjects) {
                [friendIds addObject:[friendObject objectForKey:@"id"]];
            }
            
            PFQuery *currentFriendsQuery = [PFQuery queryWithClassName:@"Contact"];
            [currentFriendsQuery whereKey:@"fromUser" equalTo:[PFUser currentUser]];
            currentFriendsQuery.limit = 1000;
            
            PFQuery *friendQuery = [PFUser query];
            [friendQuery whereKey:@"fbId" containedIn:friendIds];
            [friendQuery whereKey:@"objectId" doesNotMatchKey:@"toUserId" inQuery:currentFriendsQuery];
            [friendQuery findObjectsInBackgroundWithBlock:^(NSArray *users, NSError *error) {
                NSMutableArray *contactsToSave = [NSMutableArray array];
                for (PFObject *user in users) {
                    PFObject *contact = [PFObject objectWithClassName:@"Contact"];
                    [contact setObject:[PFUser currentUser] forKey:@"fromUser"];
                    [contact setObject:user forKey:@"toUser"];
                    [contact setObject:user.objectId forKey:@"toUserId"];
                    [contact setObject:[NSNumber numberWithInt:2] forKey:@"version"];
                    [contactsToSave addObject:contact];
                }
                
                // Save all the contacts.
                BlockWeakSelf weakSelf = self;
                [PFObject saveAllInBackground:contactsToSave block:^(BOOL succeeded, NSError *error) {
                    if ([weakSelf addressBookAccessStatus] == kABAuthorizationStatusAuthorized) {
                        [weakSelf loadAllContacts];
                    } else {
                        [weakSelf loadUserContacts];
                    }
                }];
            }];
        }
    }];
}

- (void)loadUserContactsWithCallback:(CallbackBlock)block
{
    // Load all user contacts.
    PFQuery *contactsQuery = [PFQuery queryWithClassName:@"Contact"];
    [contactsQuery whereKey:@"fromUser" equalTo:[PFUser currentUser]];
    [contactsQuery includeKey:@"toUser"];
    [contactsQuery orderByDescending:@"lastSend"];
    [contactsQuery setLimit:1000];
    [contactsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.recentContacts = [self recentContactsFromUserContacts:objects];
        
        // Only include user contacts who are actual meemchatters.
        NSMutableArray *relevantUserContacts = [NSMutableArray array];
        for (PFObject *contact in objects) {
            if ([contact objectForKey:@"toUser"]) {
                [relevantUserContacts addObject:contact];
            }
        }
        
        self.userContacts = [THContactUtils contactsSortedByDisplayNames:relevantUserContacts];
        [self.delegate userContactsDidLoad];
        block(objects, error);
    }];
}

- (void)addContact:(NSString *)username {
    // Check the contact's not already the user's friend.
    NSDictionary *params = @{@"username": username};
    [PFCloud callFunctionInBackground:@"addContact" withParameters:params block:^(id object, NSError *error) {
        if (error) {
            [self.delegate didAddContact:error];
        } else {
            [self loadUserContactsWithCallback:^(NSArray *objects, NSError *error) {
                [self.delegate didAddContact:nil];
            }];
        }
    }];
}

@end
