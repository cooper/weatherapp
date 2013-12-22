//
//  WANavigationController.m
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/30/13.
//  Copyright (c) 2013 Really Good. All rights reserved.
//

#import "WANavigationController.h"
#import "WALocationListTVC.h"
#import "WAWeatherVC.h"
#import "WAPageViewController.h"

@interface WANavigationController ()

@end

@implementation WANavigationController

- (id)initWithMyRootController {
    self.tvc  = [[WALocationListTVC alloc] initWithStyle:UITableViewStylePlain];
    self      = [super initWithRootViewController:self.tvc];
    
    UINavigationBar *bar = self.navigationBar;
    bar.titleTextAttributes = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
//    bar.barTintColor        = [UIColor clearColor];//BLUE_COLOR;
    bar.tintColor           = [UIColor whiteColor];
//    bar.backgroundColor     = [UIColor colorWithPatternImage:[UIImage imageNamed:@"icons/dummy"]];
//    bar.shadowImage         = [UIImage new];
    [self.navigationBar setBackgroundImage:[UIImage imageNamed:@"navbar"] forBarMetrics:UIBarMetricsDefault];
    self.navigationBar.shadowImage = [UIImage new];
    self.navigationBar.translucent = YES;
    
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent; 
}

#pragma mark - View controller

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
