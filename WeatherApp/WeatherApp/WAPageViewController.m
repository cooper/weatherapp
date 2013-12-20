//
//  WAPageViewController.m
//  Weather
//
//  Created by Mitchell Cooper on 12/19/13.
//  Copyright (c) 2013 Really Good. All rights reserved.
//

#import "WAPageViewController.h"
#import "WALocation.h"
#import "WAWeatherVC.h"

@interface WAPageViewController ()

@end

@implementation WAPageViewController

- (id)initWithTransitionStyle:(UIPageViewControllerTransitionStyle)style navigationOrientation:(UIPageViewControllerNavigationOrientation)navigationOrientation options:(NSDictionary *)options
{
    self = [super initWithTransitionStyle:style navigationOrientation:navigationOrientation options:options];
    if (self) {
        NSLog(@"basicly");
        self.delegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // this fixes the navigation bar inset issue.
    // however, it causes the page view controller to ignore the navigation bar completely
    // (so its frame goes behind the navigation bar as well.)
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.view.backgroundColor = TABLE_COLOR;
    refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshButtonTapped)];
    self.navigationItem.rightBarButtonItem = refreshButton;
}

- (void)viewWillAppear:(BOOL)animated {
    [self updateNavigationBar];
}

- (void)viewDidAppear:(BOOL)animated {

    // make navigation bar transparent.
    //UINavigationBar *bar = self.navigationController.navigationBar;
    //[bar setBackgroundImage:[UIImage imageNamed:@"icons/dummy"] forBarMetrics:UIBarMetricsDefault];
    //bar.shadowImage  = [UIImage new];
    //bar.barTintColor = [UIColor clearColor];
    //self.navigationController.navigationBar.translucent = YES;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers {
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    WAWeatherVC *weatherVC = self.viewControllers[0];
    self.location = weatherVC.location;
    [self updateNavigationBar];
}

- (void)setViewController:(WAWeatherVC *)weatherVC {
    [APP_DELEGATE.pageVC setViewControllers:@[weatherVC] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    self.location = weatherVC.location;
    [self updateNavigationBar];
}

- (void)updateNavigationBar {
    self.navigationItem.title = self.location.city;
    if (self.location.loading && self.navigationItem.rightBarButtonItem == refreshButton) {
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [indicator startAnimating];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:indicator];
        [self.navigationItem setRightBarButtonItem:item animated:YES];
    }
    else if (!self.location.loading && self.navigationItem.rightBarButtonItem != refreshButton)
        [self.navigationItem setRightBarButtonItem:refreshButton animated:YES];
}

- (void)refreshButtonTapped {
    [self.location fetchCurrentConditions];
}


@end
