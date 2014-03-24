//
//  WANavigationController.m
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/30/13.
//  Copyright (c) 2013-14 Mitchell Cooper. All rights reserved.
//

#import "WANavigationController.h"
#import "WALocationListTVC.h"
#import "WAWeatherVC.h"
#import "WAPageViewController.h"

@implementation WANavigationController

- (id)initWithMyRootController {
    self.tvc  = [[WALocationListTVC alloc] initWithStyle:UITableViewStylePlain];
    self      = [super initWithRootViewController:self.tvc];
    UINavigationBar *bar = self.navigationBar;

    // make bar translucently blue.
    //[bar setBackgroundImage:[UIImage imageNamed:@"navbar"] forBarMetrics:UIBarMetricsDefault];
    bar.barTintColor = BLUE_COLOR;
    bar.translucent  = YES;
    bar.tintColor    = [UIColor whiteColor];
    bar.titleTextAttributes = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent; 
}

@end
