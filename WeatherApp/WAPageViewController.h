//
//  WAPageViewController.h
//  Weather
//
//  Created by Mitchell Cooper on 12/19/13.
//  Copyright (c) 2013-14 Mitchell Cooper. All rights reserved.
//

#import "DIYMenu/DIYMenu/DIYMenu.h"
#import "DIYMenu/DIYMenu/DIYMenuItem.h"

@interface WAPageViewController : UIPageViewController <UIPageViewControllerDelegate, UIScrollViewDelegate, DIYMenuDelegate> {
    UIBarButtonItem     *refreshButton;                 // refresh button in navbar
    UIImageView         *background;                    // the background in the front
    UIImageView         *backBackground;                // the background in the back
    BOOL                goingDown;                      // user is swiping down currently
    DIYMenu             *menu;                          // our locatoin menu object
}

@property (weak) WALocation *location;                  // currently visible location

- (void)titleTapped;                                    // used to show menu from WeatherVC
- (UILabel *)menuLabelWithTitle:(NSString *)title;      // create a title label with tap gesture
- (void)setViewController:(WAWeatherVC *)weatherVC;     // set the current WeatherVC
- (void)updateNavigationBar;                            // update information in navbar

@end
