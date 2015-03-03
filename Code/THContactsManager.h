//
//  CHContactsManager.h
//  Hipframe
//
//  Created by Devin on 7/31/13.
//  Copyright (c) 2013 Devin. All rights reserved.
//
/*
 Shared singleton for loading and getting contacts from the address book and from the database.
*/

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import <Parse/Parse.h>

@protocol THContactsManagerDelegate <NSObject>

@optional
- (void)userContactsDidLoad;
- (void)allContactsDidLoad;
- (void)didAddContact:(NSError *)error;
@end

@interface THContactsManager : NSObject

+ (THContactsManager *)instance;

// An array of all contacts, including those from the address book.
@property NSArray *allContacts;

// Recent contacts.
@property NSArray *recentContacts;

// Contacts that are saved as the user's contacts in the database.
@property NSArray *userContacts;

// Contacts who are on Facebook.
@property NSArray *facebookContacts;

// Delegate who will be notified when contacts change.
@property (nonatomic, weak) NSObject<THContactsManagerDelegate> *delegate;

// Start loading all the contacts.
- (void)loadAllContacts;

// Load meemchat contacts.
- (void)loadUserContacts;

// Refresh contacts from the external data source (facebook) and load them.
- (void)refreshAndLoadContacts;

// Loads addressbook contacts.
- (void)loadAddressBookContacts;

// Add a new contact.
- (void)addContact:(NSString *)username;

// Clears all the contacts.
- (void)clearContacts;

- (ABAuthorizationStatus)addressBookAccessStatus;

@end
