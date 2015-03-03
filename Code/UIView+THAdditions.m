//
//  UIView+THAdditions.m
//  Thread
//
//  Created by Devin Finzer on 3/2/15.
//  Copyright (c) 2015 Devin Finzer. All rights reserved.
//

#import "UIView+THAdditions.h"

@implementation UIView (THAdditions)

- (void) alignTo:(UIViewAlignment)a margins:(UIEdgeInsets)e
{
    //default is to align to superview
    [self alignTo:a ofRect:self.superview.bounds margins:e];
}

- (void) alignTo:(UIViewAlignment)a
{
    [self alignTo:a margins:UIEdgeInsetsZero];
}

- (void) alignTo:(UIViewAlignment)a ofRect:(CGRect)r margins:(UIEdgeInsets)e
{
    CGRect rect = self.frame;
    
    if (a & UIViewAlignmentCenterHorizontal)
        rect.origin.x = r.origin.x + (r.size.width-rect.size.width)/2.0;
    
    if (a & UIViewAlignmentCenterVertical)
        rect.origin.y = r.origin.y + (r.size.height-rect.size.height)/2.0;
    
    if (a & UIViewAlignmentTop)
        rect.origin.y = r.origin.y;
    
    if (a & UIViewAlignmentBottom)
        rect.origin.y = r.origin.y + r.size.height-self.frame.size.height;
    
    if (a & UIViewAlignmentLeft)
        rect.origin.x = r.origin.x;
    
    if (a & UIViewAlignmentRight)
        rect.origin.x = r.origin.x + r.size.width-self.frame.size.width;
    
    rect.origin.x += e.left;
    rect.origin.x -= e.right;
    
    rect.origin.y += e.top;
    rect.origin.y -= e.bottom;
    
    self.frame = CGRectIntegral(rect);
}

- (void) alignTo:(UIViewAlignment)a ofRect:(CGRect)rect
{
    [self alignTo:a ofRect:rect margins:UIEdgeInsetsZero];
}

@end
