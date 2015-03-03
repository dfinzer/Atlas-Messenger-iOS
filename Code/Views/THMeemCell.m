//
//  MCMeemCell.m
//  Atlas Messenger
//
//  Created by Devin Finzer on 3/2/15.
//  Copyright (c) 2015 Layer, Inc. All rights reserved.
//

#import "THMeemCell.h"

@implementation THMeemCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self lyr_commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self lyr_commonInit];
    }
    return self;
}

- (void)lyr_commonInit
{
    self.backgroundColor = [UIColor blackColor];
}

- (void)presentMessage:(LYRMessage *)message
{
    
}

- (void)shouldDisplayAvatarItem:(BOOL)shouldDisplayAvatarItem
{
    
}

- (void)updateWithSender:(id<ATLParticipant>)sender
{
    
}

@end
