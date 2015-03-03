//
//  THPhotoView.h
//  Thread
//
//  Created by Devin Finzer on 3/1/15.
//  Copyright (c) 2015 Devin Finzer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface THCardView : UIView

@property (nonatomic) BOOL editable;
@property (nonatomic, strong, readwrite) NSDictionary *imageData;
@property (nonatomic, strong, readwrite) NSString *topText;
@property (nonatomic, strong, readwrite) NSString *bottomText;

@end
