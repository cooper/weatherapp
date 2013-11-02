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
    return self;
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
