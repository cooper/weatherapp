//
//  WAMenu.h
//
//  Based on DIYMenu,
//  Created by Jonathan Beilin on 8/13/12.
//
//  Copyright (c) 2014 Mitchell Cooper.
//  Copyright (c) 2012 DIY. All rights reserved.
//

@class WAMenuItem, WAWindowPassthrough;

@protocol WAMenuDelegate <NSObject>

@required
- (void)menuItemSelected:(NSString *)action;

@optional
- (void)menuActivated;
- (void)menuCancelled;

@end

@protocol WAMenuItemDelegate <NSObject>

- (void)menuAction:(NSString *)action;

@end

@interface WAMenu : UIView <WAMenuItemDelegate>

@property        NSMutableArray             *menuItems;
@property (weak) NSObject<WAMenuDelegate>   *delegate;

- (void)showMenu;
- (void)addItem:(NSString *)name icon:(UIImage *)image color:(UIColor *)color font:(UIFont *)font;

@end
