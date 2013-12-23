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

    self.navigationItem.title = L(@"Current");

    // this fixes the navigation bar inset issue.
    // however, it causes the page view controller to ignore the navigation bar completely
    // (so its frame goes behind the navigation bar as well.)
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.view.backgroundColor = [UIColor clearColor];
    refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshButtonTapped)];
    self.navigationItem.rightBarButtonItem = refreshButton;
    
    [self.view.subviews[0] setDelegate:self];
    
    background = [[UIImageView alloc] initWithFrame:self.view.bounds];
    background.backgroundColor = [UIColor clearColor];
    [self.view addSubview:background];
    [self.view sendSubviewToBack:background];
    
    backBackground = [[UIImageView alloc] initWithFrame:self.view.bounds];
    backBackground.backgroundColor = [UIColor clearColor];
    [self.view addSubview:backBackground];
    [self.view sendSubviewToBack:backBackground];

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
    WAWeatherVC *weatherVC = pendingViewControllers[0];
    self.toLocation = weatherVC.location;
    backBackground.image = self.toLocation.background;
    backBackground.frame = self.view.bounds;
    NSLog(@"to: %@, %@", self.toLocation.city, backBackground.image);
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    WAWeatherVC *weatherVC = self.viewControllers[0];
    self.location   = weatherVC.location;
    self.toLocation = nil;
    
    NSLog(@"switching from %@ to %@", background, backBackground);
    background.image        = self.location.background;
    background.alpha        = 1;
    backBackground.image    = nil;
    
    [self updateNavigationBar];
}

- (void)setViewController:(WAWeatherVC *)weatherVC {
    [APP_DELEGATE.pageVC setViewControllers:@[weatherVC] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    self.location = weatherVC.location;
    [self updateNavigationBar];
}

- (void)updateNavigationBar {
    if (self.location.loading && self.navigationItem.rightBarButtonItem == refreshButton) {
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [indicator startAnimating];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:indicator];
        [self.navigationItem setRightBarButtonItem:item animated:YES];
    }
    else if (!self.location.loading && self.navigationItem.rightBarButtonItem != refreshButton)
        [self.navigationItem setRightBarButtonItem:refreshButton animated:YES];
    [self updateBackground];
}

- (void)refreshButtonTapped {
    [self.location fetchCurrentConditions];
}

#pragma mark - Scroll view delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // 568/100 = yOffset/x
    // x(568/100) = yOffset
    // x = yOffset/(568/100)
    CGFloat x = scrollView.contentOffset.y / (568.00/100.00);
    
    // we're going the opposite way.
    if (x > 100.00) x = 100 - (x - 100);
    
    background.alpha = x / 100;
}

- (void)updateBackground {
    background.image = self.location.background;
    background.frame = self.view.bounds;
}

@end
