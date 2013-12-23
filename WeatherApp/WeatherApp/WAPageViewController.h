//
//  WAPageViewController.h
//  Weather
//
//  Created by Mitchell Cooper on 12/19/13.
//  Copyright (c) 2013 Really Good. All rights reserved.
//

@interface WAPageViewController : UIPageViewController <UIPageViewControllerDelegate, UIScrollViewDelegate> {
    UIBarButtonItem *refreshButton;
    UIImageView *background;
    UIImageView *backBackground;

}

@property (weak) WALocation *location;
@property (weak) WALocation *toLocation;

- (void)setViewController:(WAWeatherVC *)weatherVC;
- (void)updateNavigationBar;

@end
