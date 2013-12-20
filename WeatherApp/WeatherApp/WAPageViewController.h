//
//  WAPageViewController.h
//  Weather
//
//  Created by Mitchell Cooper on 12/19/13.
//  Copyright (c) 2013 Really Good. All rights reserved.
//

@interface WAPageViewController : UIPageViewController <UIPageViewControllerDelegate> {
    UIBarButtonItem *refreshButton;
}

@property (weak) WALocation *location;

- (void)setViewController:(WAWeatherVC *)weatherVC;

@end
