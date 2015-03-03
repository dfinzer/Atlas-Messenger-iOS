//
//  MCMeemCell.m
//  Atlas Messenger
//
//  Created by Devin Finzer on 3/2/15.
//  Copyright (c) 2015 Layer, Inc. All rights reserved.
//

#import "THCardCell.h"
#import "THCardView.h"

#import "NSMutableDictionary+THAdditions.h"

#define kCardViewPadding 5.0

@interface THCardCell()

@property (nonatomic, strong, readwrite) THCardView *cardView;

@end

@implementation THCardCell

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
    self.cardView = [[THCardView alloc] init];
    [self addSubview:self.cardView];
}

- (void)layoutSubviews
{
    
}

- (void)presentMessage:(LYRMessage *)message
{
    LYRMessagePart *messagePart = message.parts[0];
    
    NSLog(@"Mime type: %@", messagePart.MIMEType);
    if ([messagePart.MIMEType isEqualToString:@"application/json"]) {
        NSDictionary *meemData = [NSJSONSerialization JSONObjectWithData:messagePart.data options:0 error:nil];
        NSString *imageUrl = [meemData objectForKey:@"image_url"];
        NSString *thumbnailUrl = [meemData objectForKey:@"thumbnail_url"];
        
        // Set card view position.
        CGRect cardViewFrame = CGRectZero;
        cardViewFrame.origin.x = CGRectGetMinX(self.bounds) + kCardViewPadding;
        cardViewFrame.origin.y = CGRectGetMinY(self.bounds) + kCardViewPadding;
        cardViewFrame.size.width = CGRectGetWidth(self.bounds) - 2 * kCardViewPadding;
        cardViewFrame.size.height = CGRectGetWidth(self.bounds) - 2 * kCardViewPadding;
        
        self.cardView.frame = cardViewFrame;
        
        // Set image data.
        NSMutableDictionary *imageData = [[NSMutableDictionary alloc] init];;
        [imageData setObjectSafe:imageUrl forKey:@"image_url"];
        [imageData setObjectSafe:thumbnailUrl forKey:@"thumbnail_url"];
        self.cardView.imageData = imageData;
    }
}

- (void)shouldDisplayAvatarItem:(BOOL)shouldDisplayAvatarItem
{
    
}

- (void)updateWithSender:(id<ATLParticipant>)sender
{
    
}

@end
