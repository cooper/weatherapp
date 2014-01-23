//
//  WAPageViewController.h
//  Weather
//
//  Created by Mitchell Cooper on 12/19/13.
//  Copyright (c) 2013-14 Mitchell Cooper. All rights reserved.
//

@interface WAPageViewController : UIPageViewController <UIPageViewControllerDelegate, UIScrollViewDelegate> {
    UIBarButtonItem *refreshButton;
    UIImageView *backBackground;
    BOOL goingDown;
}

@property (weak) WALocation *location;
@property UIImageView *background;

- (void)setViewController:(WAWeatherVC *)weatherVC;
- (void)updateNavigationBar;

@end
