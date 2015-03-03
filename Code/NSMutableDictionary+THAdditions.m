//
//  NSMutableDictionary+THAdditions.m
//  Thread
//
//  Created by Devin Finzer on 3/2/15.
//  Copyright (c) 2015 Devin Finzer. All rights reserved.
//

#import "NSMutableDictionary+THAdditions.h"

@implementation NSMutableDictionary (THAdditions)

- (void)setObjectSafe:(id)object forKey:(NSString *)key
{
    if (object) {
        [self setObject:object forKey:key];
    }
}

@end
