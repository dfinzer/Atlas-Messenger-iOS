//
//  ATLMUIParticipantPickerDataSource.m
//  Atlas Messenger
//
//  Created by Kevin Coleman on 9/2/14.
//  Copyright (c) 2014 Layer, Inc. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "ATLMParticipantDataSource.h"
#import "THContactsManager.h"

@interface ATLMParticipantDataSource ()

@property (nonatomic) ATLMPersistenceManager *persistenceManager;

@end

@implementation ATLMParticipantDataSource

+ (instancetype)participantDataSourceWithPersistenceManager:(ATLMPersistenceManager *)persistenceManager
{
    return [[self alloc] initWithPersistenceManager:persistenceManager];
}

- (id)initWithPersistenceManager:(ATLMPersistenceManager *)persistenceManager
{
    self = [super init];
    if (self) {
        _persistenceManager = persistenceManager;
    }
    return self;
}

- (id)init
{
     @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Failed to call designated initializer." userInfo:nil];
}

#pragma mark - LYRUIParticipantPickerDataSource

- (id<ATLParticipant>)participantForIdentifier:(NSString *)identifier
{
    if ([self.excludedIdentifiers containsObject:identifier]) {
        return nil;
    }
    return [self.persistenceManager userForIdentifier:identifier];
}

- (void)participantsMatchingSearchText:(NSString *)searchText completion:(void (^)(NSSet *))completion
{
    [self.persistenceManager performUserSearchWithString:searchText completion:^(NSArray *users, NSError *error) {
        NSPredicate *exclusionPredicate = [NSPredicate predicateWithFormat:@"NOT participantIdentifier IN %@", self.excludedIdentifiers];
        NSArray *availableParticipants = [users filteredArrayUsingPredicate:exclusionPredicate];
        completion([NSSet setWithArray:availableParticipants]);
    }];
}

- (NSSet *)participants
{
    NSArray *contacts = [[THContactsManager instance] userContacts];
    NSMutableSet *participants = [NSMutableSet set];
    for (PFUser *contact in contacts) {
        
    }
    
    NSMutableSet *participants = [[self.persistenceManager persistedUsersWithError:nil] mutableCopy];
    NSSet *participantsToExclude = [self.persistenceManager usersForIdentifiers:self.excludedIdentifiers];
    [participants minusSet:participantsToExclude];
    return participants;
}

@end
