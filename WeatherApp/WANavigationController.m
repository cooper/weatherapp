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

- (instancetype)initWithMyRootController {
    WALocationListTVC *locationList = [[WALocationListTVC alloc] initWithStyle:UITableViewStylePlain];
    self = [super initWithRootViewController:locationList];
    self.locationList = locationList;
    
    // make bar translucently blue.
    UINavigationBar *bar    = self.navigationBar;
    bar.barTintColor        = BLUE_COLOR;
    bar.translucent         = YES;
    bar.tintColor           = [UIColor whiteColor];
    bar.titleTextAttributes = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent; 
}

@end
