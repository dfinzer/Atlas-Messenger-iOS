//
//  UIView+THAdditions.h
//  Thread
//
//  Created by Devin Finzer on 3/2/15.
//  Copyright (c) 2015 Devin Finzer. All rights reserved.
//

#import <UIKit/UIKit.h>

enum
{
    UIViewAlignmentTop                  = 1 << 0,
    UIViewAlignmentBottom               = 1 << 1,
    UIViewAlignmentLeft                 = 1 << 2,
    UIViewAlignmentRight                = 1 << 3,
    UIViewAlignmentCenterHorizontal     = 1 << 4,
    UIViewAlignmentCenterVertical       = 1 << 5,
    UIViewAlignmentCenter               = UIViewAlignmentCenterHorizontal | UIViewAlignmentCenterVertical
}
typedef UIViewAlignment; // (accepts masking)


@interface UIView (THAdditions)

// Aligns frame based on the bounds of the sender's superview
- (void) alignTo:(UIViewAlignment)a;
- (void) alignTo:(UIViewAlignment)a margins:(UIEdgeInsets)e;

// Aligns frame based on the given rect
- (void) alignTo:(UIViewAlignment)a ofRect:(CGRect)r;
- (void) alignTo:(UIViewAlignment)a ofRect:(CGRect)r margins:(UIEdgeInsets)e;

@end
