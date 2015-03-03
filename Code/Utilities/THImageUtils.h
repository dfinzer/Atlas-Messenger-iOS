//
//  THImageUtils.h
//  Thread
//
//  Created by Devin Finzer on 3/1/15.
//  Copyright (c) 2015 Devin Finzer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface THImageUtils : NSObject

+ (UIImage *)fullImageForImage:(UIImage *)image;
+ (UIImage *)thumbnailForImage:(UIImage *)image;
+ (UIImage *)cropImage:(UIImage *)image withRect:(CGRect)cropRect;
+ (UIImage *)resizeImage:(UIImage *)image withSize:(CGSize)size;

@end
