//
//  WAMenuItem.h
//
//  Based on DIYMenu,
//  Created by Jonathan Beilin on 8/13/12.
//
//  Copyright (c) 2014 Mitchell Cooper.
//  Copyright (c) 2012 DIY. All rights reserved.
//

#import "WAMenu.h"

@interface WAMenuItem : UIView

@property (weak)    NSObject<WAMenuItemDelegate>  *delegate;
@property           BOOL                          isSelected;
@property           UIView                        *shadingView;
@property           CGPoint                       menuPosition;
@property           UILabel                       *name;
@property           UIImageView                   *icon;

- (void)setName:(NSString *)name icon:(UIImage *)image color:(UIColor *)color font:(UIFont *)font;

@end
