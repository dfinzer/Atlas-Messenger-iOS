//
//  NSMutableDictionary+THAdditions.h
//  Thread
//
//  Created by Devin Finzer on 3/2/15.
//  Copyright (c) 2015 Devin Finzer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (THAdditions)

- (void)setObjectSafe:(id)object forKey:(NSString *)key;

@end

