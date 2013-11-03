//
//  WANavigationController.m
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/30/13.
//  Copyright (c) 2013 Really Good. All rights reserved.
//

#import "WANavigationController.h"
#import "WAAppDelegate.h"
#import "WATableViewController.h"

@interface WANavigationController ()

@end

@implementation WANavigationController

- (id)initWithMyRootController {
    self.tvc  = [[WATableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    self      = [super initWithRootViewController:self.tvc];
    self.navigationBar.barTintColor = BLUE_COLOR;
    self.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    self.navigationBar.tintColor = [UIColor whiteColor];
    return self;
}

-(UIStatusBarStyle)preferredStatusBarStyle {
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
