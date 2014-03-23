//
//  WAPageViewController.h
//  Weather
//
//  Created by Mitchell Cooper on 12/19/13.
//  Copyright (c) 2013-14 Mitchell Cooper. All rights reserved.
//

#import "DIYMenu/DIYMenu/DIYMenu.h"

@interface WAPageViewController : UIPageViewController <UIPageViewControllerDelegate, UIScrollViewDelegate, DIYMenuDelegate> {
    UIBarButtonItem *refreshButton;
    UIImageView *backBackground;
    BOOL goingDown;
    DIYMenu *menu;
}

@property (weak) WALocation *location;
@property UIImageView *background;

- (void)titleTapped;
- (UILabel *)menuLabelWithTitle:(NSString *)title;
- (void)setViewController:(WAWeatherVC *)weatherVC;
- (void)updateNavigationBar;

@end
