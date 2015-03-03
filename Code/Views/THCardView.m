//
//  THPhotoView.m
//  Thread
//
//  Created by Devin Finzer on 3/1/15.
//  Copyright (c) 2015 Devin Finzer. All rights reserved.
//

#import "THCardView.h"
#import "THDefines.h"
#import "THImageUtils.h"
#import "THOutlinedTextLabel.h"

#import <MBProgressHUD/MBProgressHUD.h>
#import <SDWebImage/SDWebImageOperation.h>
#import <SDWebImage/UIImageView+WebCache.h>

#define kLineHeight 40.0

@interface THCardView() <UITextViewDelegate>

@property (nonatomic, strong, readwrite) UIImageView *imageView;
@property (nonatomic, strong, readwrite) MBProgressHUD *progressHUD;
@property (nonatomic, strong, readwrite) UITextView *topTextView;
@property (nonatomic, strong, readwrite) UILabel *topTextLabel;
@property (nonatomic, strong, readwrite) UITextView *bottomTextView;
@property (nonatomic, strong, readwrite) UILabel *bottomTextLabel;
@property (nonatomic, strong, readwrite) UIActivityIndicatorView *loadingIndicator;

@property (nonatomic, assign) CGFloat bottomTextViewMaxY;
@property (nonatomic, assign) BOOL hasEdited;
@property (nonatomic, weak) id <SDWebImageOperation> imageOperation;

@end

@implementation THCardView

- (id)init
{
    self = [self initWithFrame:CGRectZero];
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        self.layer.borderWidth = 1.0f;
        self.layer.cornerRadius = 5.0f;
        
        self.imageView = [[UIImageView alloc] initWithFrame:frame];
        self.backgroundColor = [UIColor blueColor];
        [self addSubview:self.imageView];
        
        // Add tap gesture recognizer.
        UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        [self addGestureRecognizer:singleFingerTap];
        
        // Add a gesture recognizer for moving the image around.
        UIPanGestureRecognizer *gesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(imageDragged:)];
        [self addGestureRecognizer:gesture];
        
        // Memify text views and labels.
        self.topTextView = [self memeTextView];
        [self addSubview:self.topTextView];
        self.bottomTextView = [self memeTextView];
        [self addSubview:self.bottomTextView];
        self.topTextLabel = [self memeTextLabel];
        [self addSubview:self.topTextLabel];
        self.bottomTextLabel = [self memeTextLabel];
        [self addSubview:self.bottomTextLabel];
        
        // Progress HUDs.
        self.progressHUD = [[MBProgressHUD alloc] initWithView:self];
        self.progressHUD.opacity = 0.5f;
        [self addSubview:self.progressHUD];
        
        self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [self.loadingIndicator startAnimating];
        [self addSubview:self.loadingIndicator];
    }
    return self;
}

- (UITextView *)memeTextView
{
    UITextView *textView = [[UITextView alloc] init];
    textView.backgroundColor = [UIColor clearColor];
    textView.font = [self memeTextFont];
    textView.textColor = [UIColor whiteColor];
    textView.textAlignment = NSTextAlignmentCenter;
    textView.returnKeyType = UIReturnKeyDone;
    textView.delegate = self;
    textView.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    textView.autocorrectionType = UITextAutocorrectionTypeNo;
    textView.textContainer.lineFragmentPadding = 0;
    textView.textContainerInset = UIEdgeInsetsZero;
    textView.scrollEnabled = NO;

    return textView;
}

- (UILabel *)memeTextLabel
{
    THOutlinedTextLabel *textLabel = [[THOutlinedTextLabel alloc] init];
    textLabel.backgroundColor = [UIColor clearColor];
    textLabel.textColor = [UIColor whiteColor];
    textLabel.textAlignment = NSTextAlignmentCenter;
    textLabel.font = [self memeTextFont];
    textLabel.numberOfLines = 2;
    
    return textLabel;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.bottomTextViewMaxY == 0) {
        self.bottomTextViewMaxY = CGRectGetMaxY(self.bounds);
    }
    
    self.topTextLabel.text = self.topTextView.text;
    self.bottomTextLabel.text = self.bottomTextView.text;
    
    CGRect topTextFrame = CGRectMake(0, 0, self.bounds.size.width, 2 * kLineHeight);
    self.topTextView.frame = topTextFrame;
    self.topTextLabel.frame = CGRectMake(0, 0, self.bounds.size.width, 2 * kLineHeight);
    [self.topTextLabel sizeToFit];
    self.topTextLabel.frame = CGRectMake(0, 0, self.topTextView.frame.size.width, self.topTextLabel.frame.size.height);
    
    // Calculate size of bottom text view.
    [self.bottomTextView sizeToFit];
    CGRect bottomTextFrame = CGRectZero;
    bottomTextFrame.origin.x = CGRectGetMinX(self.bounds);
    bottomTextFrame.origin.y = self.bottomTextViewMaxY - self.bottomTextView.frame.size.height;
    bottomTextFrame.size.width = CGRectGetWidth(self.bounds);
    bottomTextFrame.size.height = self.bottomTextView.frame.size.height;
    self.bottomTextView.frame = bottomTextFrame;
    self.bottomTextLabel.frame = bottomTextFrame;
    
    self.topTextView.hidden = !self.editable;
    self.bottomTextView.hidden = !self.editable;
    
    // If it's not editable, add a light border and removed gesture recognizers.
    if (!self.editable) {
        // Remove all gesture recognizers.
        while (self.gestureRecognizers.count) {
            [self removeGestureRecognizer:[self.gestureRecognizers objectAtIndex:0]];
        }
    }
    
    self.loadingIndicator.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
}

- (UIFont *)memeTextFont
{
    return [UIFont fontWithName:@"impact" size:28.0];
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    if (self.editable) {
        if (self.topTextView.isFirstResponder) {
            [self.topTextView resignFirstResponder];
            
            CGPoint point = [recognizer locationInView:self];
            if (point.y > .25 * self.bounds.size.width) {
                [self.bottomTextView becomeFirstResponder];
            }
        } else if (self.bottomTextView.isFirstResponder) {
            [self.bottomTextView resignFirstResponder];
        } else {
            CGPoint point = [recognizer locationInView:self];
            if (point.y > .5 * self.bounds.size.height) {
                [self.bottomTextView becomeFirstResponder];
            } else {
                [self.topTextView becomeFirstResponder];
            }
        }
    }
}

- (void)imageDragged:(UIPanGestureRecognizer *)gesture
{
    [self dragView:gesture view:self.imageView biggerThanView:YES];
}

- (BOOL)fits:(CGRect)draggedFrame bigger:(BOOL)bigger
{
    BOOL fits = NO;
    if (bigger) {
        fits = CGRectContainsRect(draggedFrame, self.bounds);
    } else {
        fits = CGRectContainsRect(self.bounds, draggedFrame);
    }
    return fits;
}

- (void)dragView:(UIPanGestureRecognizer *)gesture view:(UIView *)theView biggerThanView:(BOOL)bigger
{
    BOOL canDrag = NO;
    
    CGPoint translation = [gesture translationInView:theView];
    
    // Move view.
    CGPoint point = CGPointMake(theView.center.x + translation.x,
                                theView.center.y + translation.y);
    CGRect newFrame = CGRectMake(theView.frame.origin.x + translation.x, theView.frame.origin.y + translation.y, theView.frame.size.width, theView.frame.size.height);
    canDrag = [self fits:newFrame bigger:bigger];
    
    // Otherwise, try just dragging vertically.
    if (!canDrag) {
        point = CGPointMake(theView.center.x, theView.center.y + translation.y);
        newFrame = CGRectMake(theView.frame.origin.x, theView.frame.origin.y + translation.y, theView.frame.size.width, theView.frame.size.height);
        
        canDrag = [self fits:newFrame bigger:bigger];
    }
    
    // Finally, try just dragging horizontally.
    if (!canDrag) {
        point = CGPointMake(theView.center.x + translation.x, theView.center.y);
        newFrame = CGRectMake(theView.frame.origin.x + translation.x, theView.frame.origin.y, theView.frame.size.width, theView.frame.size.height);
        
        canDrag = [self fits:newFrame bigger:bigger];
    }
    
    // Move it.
    if (canDrag) {
        theView.center = point;
        
        // Reset translation
        [gesture setTranslation:CGPointZero inView:theView];
    }
}

// Entry field movement.
- (void)moveBottomTextFieldToYCoord:(CGFloat)yCoord withAnimationDuration:(NSTimeInterval)duration
{
    [UIView beginAnimations:@"animationView" context:nil];
    [UIView setAnimationDuration:duration];
    
    // Move the meemified textFrame.
    CGRect bottomTextFieldFrame = self.bottomTextView.frame;
    bottomTextFieldFrame.origin.y = yCoord;
    self.bottomTextView.frame = bottomTextFieldFrame;
    self.bottomTextLabel.frame = bottomTextFieldFrame;
    self.bottomTextViewMaxY = CGRectGetMaxY(bottomTextFieldFrame);
    [UIView commitAnimations];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if (!self.hasEdited) {
        self.topText = @"";
        self.bottomText = @"";
    }
    self.hasEdited = YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    [self setNeedsLayout];
}

- (UIImage *)paddedScreenshot
{
    // Screenshot the Meemchat
    CGRect rect = self.bounds;
    UIGraphicsBeginImageContextWithOptions(rect.size, YES, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.layer renderInContext:context];
    UIImage *capturedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Throw on a border and add the meemchat logo
    CGFloat paddingHeight = 100;
    CGRect paddingRect = CGRectMake(0, 0, rect.size.width, rect.size.height + (2*paddingHeight));
    UIGraphicsBeginImageContextWithOptions(paddingRect.size, YES, 0.0f);
    [[UIColor blackColor] set];
    UIRectFill(paddingRect);
    [capturedImage drawInRect:CGRectMake(0, paddingHeight, self.bounds.size.width, self.bounds.size.height)];
    CGFloat logoSpacing = 3;
    CGFloat logoWidth = self.bounds.size.height/3;
    CGFloat logoHeight = logoWidth*0.1733;
    UIImage *meemchatLogo = [UIImage imageNamed:@"meemchatheader.png"];
    [meemchatLogo drawInRect:CGRectMake(self.bounds.size.width * 2.0/3.0, self.bounds.size.height + paddingHeight + logoSpacing, logoWidth, logoHeight)];
    UIImage *paddedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return paddedImage;
}

- (UIImage *)screenshot
{
    CGRect rect = self.bounds;
    UIGraphicsBeginImageContextWithOptions(rect.size, YES, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.layer renderInContext:context];
    UIImage *capturedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return capturedImage;
}

- (UIFont *)textFieldFont
{
    return [UIFont boldSystemFontOfSize:16.0];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    // Handle return key.
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        
        BOOL bottomTextIsEmpty = !self.bottomTextView.text || [self.bottomTextView.text isEqualToString:@""];
        if (textView == self.topTextView && bottomTextIsEmpty) {
            [self.bottomTextView becomeFirstResponder];
        }
        
        return NO;
    }
    
    // Calculate the size with the new text.
    NSString *newText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    NSDictionary *attributes = @{NSFontAttributeName:[self memeTextFont]};
    CGSize sizeWithFont = [newText boundingRectWithSize:CGSizeMake(textView.frame.size.width, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil].size;
    
    BOOL shouldChangeText = NO;
    if (textView == self.topTextView) {
        if (sizeWithFont.height < textView.frame.size.height) {
            shouldChangeText = YES;
            self.topTextLabel.text = newText;
        }
    } else if (textView == self.bottomTextView) {
        if (sizeWithFont.height < 2 * kLineHeight) {
            self.bottomTextLabel.text = newText;
            shouldChangeText = YES;
            [self setNeedsLayout];
        }
    }
    if (shouldChangeText) {
        [self setNeedsLayout];
    }
    return shouldChangeText;
}

- (void)downloadImage:(NSString *)imageUrl withCallback:(void(^)(UIImage *image, NSError *error, SDImageCacheType cacheType))callback
{
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    __weak typeof(self) weakSelf = self;
    self.imageOperation = [manager downloadImageWithURL:[NSURL URLWithString:imageUrl] options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
        callback(image, error, cacheType);
        weakSelf.imageOperation = nil;
    }];
}

- (void)setImageData:(NSDictionary *)imageData
{
    _imageData = imageData;
    
    NSString *thumbnailUrlString = imageData[@"thumbnail_url"];
    NSString *imageUrlString = imageData[@"image_url"];
    
    if (self.imageOperation) {
        [self.imageOperation cancel];
    }
    
    BlockWeakSelf weakSelf = self;
    [self.imageView sd_cancelCurrentImageLoad];
    if ([[SDImageCache sharedImageCache] diskImageExistsWithKey:imageUrlString]) {
        [self hideProgressHUD];
        
        [self downloadImage:imageUrlString withCallback:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            [weakSelf layoutImage:image];
        }];
    } else if ([[SDImageCache sharedImageCache] diskImageExistsWithKey:thumbnailUrlString]) {
        [weakSelf downloadImage:thumbnailUrlString withCallback:^(UIImage *thumbnailImage, NSError *error, SDImageCacheType cacheType) {
            if ([weakSelf.imageData[@"thumbnail_url"] isEqualToString:thumbnailUrlString]) {
                [weakSelf layoutImage:thumbnailImage];
                [weakSelf showProgressHUD];
                
                [weakSelf downloadImage:imageUrlString withCallback:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                    if ([weakSelf.imageData[@"image_url"] isEqualToString:imageUrlString]) {
                        [weakSelf hideProgressHUD];
                        if (image) {
                            [weakSelf layoutImage:image];
                        }
                    }
                }];
            }
        }];
    } else {
        [weakSelf showProgressHUD];
        [self downloadImage:imageUrlString withCallback:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            [weakSelf hideProgressHUD];
            [weakSelf layoutImage:image];
        }];
    }
}

- (void)layoutImage:(UIImage *)image
{
    UIImage *resizedImage = [THImageUtils fullImageForImage:image];
    CGSize imageSize = resizedImage.size;
    
    CGRect bounds = self.bounds;
    if (CGRectEqualToRect(self.bounds, CGRectZero)) {
        bounds = CGRectMake(0, 0, 310.0, 310.0);
    }
    
    // If it's a thumbnail, just leave it be.
    if (imageSize.width < self.bounds.size.width) {
        self.imageView.frame = self.bounds;
    } else {
        // Adjust image so it's cropped appropriately.
        CGFloat x = 0;
        CGFloat y = 0;
        // If height is bigger than width, center vertically.
        if (imageSize.height > imageSize.width) {
            x = CGRectGetMinX(bounds);
            y = CGRectGetMidY(bounds) - imageSize.height / 2;
        } else {
            x = CGRectGetMidX(bounds) - imageSize.width / 2;
            y = CGRectGetMinY(bounds);
        }
        self.imageView.frame = CGRectMake(x, y, imageSize.width, imageSize.height);
    }
    self.imageView.image = resizedImage;
    
    [self setNeedsLayout];
}

- (void)showProgressHUD
{
    if (!self.editable) {
        self.bottomTextLabel.hidden = YES;
        self.topTextLabel.hidden = YES;
    }
    [self.loadingIndicator startAnimating];
}

- (void)hideProgressHUD
{
    if (!self.editable) {
        self.bottomTextLabel.hidden = NO;
        self.topTextLabel.hidden = NO;
    }
    [self.loadingIndicator stopAnimating];
}

- (void)setEditable:(BOOL)editable
{
    _editable = editable;
    [self setNeedsLayout];
}

- (void)setTopText:(NSString *)topText
{
    self.topTextView.text = topText;
    self.topTextLabel.text = topText;
    [self setNeedsLayout];
}

- (NSString *)topText
{
    return self.topTextView.text;
}

- (void)setBottomText:(NSString *)bottomText
{
    self.bottomTextView.text = bottomText;
    self.bottomTextLabel.text = bottomText;
    [self setNeedsLayout];
}

- (NSString *)bottomText
{
    return self.bottomTextView.text;
}

- (void)showSavingImage
{
    self.progressHUD.labelText = @"Saving Image";
    [self.progressHUD show:YES];
}

- (void)hideSavingImage
{
    [self.progressHUD hide:YES];
    self.progressHUD.labelText = @"";
}

- (CGRect)cropRect
{
    return [self.imageView convertRect:self.bounds fromView:self];
}

- (CGRect)bottomTextFrame
{
    return self.bottomTextView.frame;
}

- (void)setImage:(UIImage *)image
{
    [self layoutImage:image];
}

- (UIImage *)image
{
    return self.imageView.image;
}

@end
