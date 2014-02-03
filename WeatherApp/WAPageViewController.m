//
//  WAPageViewController.m
//  Weather
//
//  Created by Mitchell Cooper on 12/19/13.
//  Copyright (c) 2013-14 Mitchell Cooper. All rights reserved.
//

#import "WAPageViewController.h"
#import "WALocation.h"
#import "WAWeatherVC.h"
#import "WALocationManager.h"

@implementation WAPageViewController

@synthesize background = background;

#pragma mark - Page view controller

- (id)initWithTransitionStyle:(UIPageViewControllerTransitionStyle)style navigationOrientation:(UIPageViewControllerNavigationOrientation)navigationOrientation options:(NSDictionary *)options {
    self = [super initWithTransitionStyle:style navigationOrientation:navigationOrientation options:options];
    if (self) self.delegate = self; // we'll never destroy the page VC anyway.
    return self;
}

- (void)setViewController:(WAWeatherVC *)weatherVC {
    [appDelegate.pageVC setViewControllers:@[weatherVC] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    self.location = weatherVC.location;
    [self updateNavigationBar];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // this fixes the navigation bar inset issue.
    // however, it causes the page view controller to ignore the navigation bar completely
    // (so its frame goes behind the navigation bar as well.)
    self.automaticallyAdjustsScrollViewInsets = NO;
        
    self.view.backgroundColor      = [UIColor clearColor];
    self.view.multipleTouchEnabled = NO;
    self.navigationItem.title      = @"Conditions";
    
    // refresh button.
    refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshButtonTapped)];
    self.navigationItem.rightBarButtonItem = refreshButton;
    
    // remove the text on the back button.
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    // scroll view delegate.
    [self.view.subviews[0] setDelegate:self];
    
    // from background.
    self.background = background = [[UIImageView alloc] initWithFrame:self.view.bounds];
    background.backgroundColor = [UIColor clearColor];
    [self.view addSubview:background];
    [self.view sendSubviewToBack:background];
    
    // to background.
    backBackground = [[UIImageView alloc] initWithFrame:self.view.bounds];
    backBackground.backgroundColor = [UIColor clearColor];
    [self.view addSubview:backBackground];
    [self.view sendSubviewToBack:backBackground];

}

- (void)viewWillAppear:(BOOL)animated {
    [self updateNavigationBar];
}

#pragma mark - Page view controller delegate

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers {
    WAWeatherVC *toVC = pendingViewControllers[0];
    NSUInteger i      = goingDown ? toVC.location.index - 1 : toVC.location.index + 1;
    
    WALocation *locationBefore = appDelegate.locationManager.locations[i];
    background.image = locationBefore.background;
    background.frame = self.view.bounds;
    
    backBackground.image = toVC.location.background;
    backBackground.frame = self.view.bounds;
    
    NSLog(@"Transitioning to %@", toVC.location.city);
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    WAWeatherVC *weatherVC = self.viewControllers[0];
    NSLog(@"Setting current city from %@ to %@", self.location.city, weatherVC.location.city);
    self.location = weatherVC.location;
    if (completed) [self updateNavigationBar]; // fixes it.
}

#pragma mark - Update information

// update the information and buttons on the navigation bar.
- (void)updateNavigationBar {

    // loading and refresh button is visible.
    if (self.location.loading && self.navigationItem.rightBarButtonItem == refreshButton) {
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [indicator startAnimating];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:indicator];
        [self.navigationItem setRightBarButtonItem:item animated:YES];
    }
    
    // not loading and refresh button is not visible.
    else if (!self.location.loading && self.navigationItem.rightBarButtonItem != refreshButton)
        [self.navigationItem setRightBarButtonItem:refreshButton animated:YES];
    
    // update the background while we're at it.
    [self updateBackground];
    
}

// update the background image.
- (void)updateBackground {
    background.image = self.location.background;
    background.frame = self.view.bounds;
}

#pragma mark - Interface actions

// update conditions.
- (void)refreshButtonTapped {
    [self.location fetchCurrentConditions];
}

#pragma mark - Scroll view delegate

// gradually fade the background with scrolling.
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat x = scrollView.contentOffset.y / (self.view.bounds.size.height / 100.);
    
    // up or down?
    if (x > 100.) goingDown = YES;
    else goingDown = NO;

    // going down, so subtract from 200.
    if (x > 100.) x = 200. - x;
    
    background.alpha = x / 100.;
}

@end
