//
//  UIButton+THAdditions.m
//  Thread
//
//  Created by Devin Finzer on 3/2/15.
//  Copyright (c) 2015 Devin Finzer. All rights reserved.
//

#import "UIButton+THAdditions.h"

@implementation UIButton (THAdditions)

+ (UIButton *)buttonWithImage:(UIImage *)image
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:image forState:UIControlStateNormal];
    button.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    return button;
}

@end