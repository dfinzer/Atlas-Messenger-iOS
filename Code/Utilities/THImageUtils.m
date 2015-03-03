//
//  THImageUtils.m
//  Thread
//
//  Created by Devin Finzer on 3/1/15.
//  Copyright (c) 2015 Devin Finzer. All rights reserved.
//

#import "THImageUtils.h"

@implementation THImageUtils

+ (UIImage *)cropImage:(UIImage *)image
{
    // Crop image.
    CGFloat width;
    CGFloat height;
    if (image.size.width > image.size.height) {
        width = image.size.height;
        height = image.size.height;
    } else {
        width = image.size.width;
        height = image.size.width;
    }
    CGFloat x = (image.size.width - width) / 2.0;
    CGFloat y = (image.size.height - height) / 2.0;
    CGRect cropRect = CGRectMake(x, y, width, height);
    return [self cropImage:image withRect:cropRect];
}

+ (UIImage *)cropImage:(UIImage *)image withRect:(CGRect)cropRect
{
    CGImageRef croppedImg = CGImageCreateWithImageInRect(image.CGImage, cropRect);
    return [UIImage imageWithCGImage:croppedImg];
}

+ (UIImage *)resizeImage:(UIImage *)image withSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    [image drawInRect: CGRectMake(0, 0, size.width, size.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resizedImage;
}

+ (UIImage *)thumbnailForImage:(UIImage *)image
{
    // Crop image.
    UIImage *croppedImage = [self cropImage:image];
    
    // Create thumbnail.
    return [self resizeImage:croppedImage withSize:CGSizeMake(106.0, 106.0)];
}

+ (UIImage *)fullImageForImage:(UIImage *)image
{
    CGFloat aspectRatio = image.size.width / image.size.height;
    CGSize size;
    CGFloat desiredDimension = 310.0;
    if (image.size.width > image.size.height) {
        // Pin height.
        size = CGSizeMake(desiredDimension * aspectRatio, desiredDimension);
    } else {
        // Pin width.
        size = CGSizeMake(desiredDimension, desiredDimension / aspectRatio);
    }
    
    return [self resizeImage:image withSize:size];
}

@end
