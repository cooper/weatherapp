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
    tvc  = [[WATableViewController alloc] initWithNibName:@"WATableViewController" bundle:nil];
    self = [super initWithRootViewController:tvc];
    return self;
}

#pragma mark - UIViewController

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
