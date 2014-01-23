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
#import "WALocationManager.h"

@interface WAPageViewController ()

@end

@implementation WAPageViewController

@synthesize background = background;

- (id)initWithTransitionStyle:(UIPageViewControllerTransitionStyle)style navigationOrientation:(UIPageViewControllerNavigationOrientation)navigationOrientation options:(NSDictionary *)options
{
    self = [super initWithTransitionStyle:style navigationOrientation:navigationOrientation options:options];
    if (self) {
        NSLog(@"basicly");
        self.delegate = self; // FIXME: is this a problem?
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    //self.navigationItem.title = L(@"Current");

    // this fixes the navigation bar inset issue.
    // however, it causes the page view controller to ignore the navigation bar completely
    // (so its frame goes behind the navigation bar as well.)
    self.automaticallyAdjustsScrollViewInsets = NO;
        
    self.view.backgroundColor = [UIColor clearColor];
    refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshButtonTapped)];
    self.navigationItem.rightBarButtonItem = refreshButton;
    self.navigationItem.title = @"Conditions";
    
    // remove the text on the back button.
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    [self.view.subviews[0] setDelegate:self];
    self.view.multipleTouchEnabled = NO;
    
    self.background = background = [[UIImageView alloc] initWithFrame:self.view.bounds];
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
    NSLog(@"WILL TRANSITION FROM/TO: %@, %@", self.viewControllers, pendingViewControllers);
    WAWeatherVC *toVC   = pendingViewControllers[0];
    //WAWeatherVC *fromVC = self.viewControllers[0];
    
    NSUInteger i = goingDown ? toVC.location.index - 1 : toVC.location.index + 1;
    // TODO: make sure this index exists just as a double check.
    WALocation *locationBefore = APP_DELEGATE.locationManager.locations[i];
    background.image = locationBefore.background;
    background.frame = self.view.bounds;
    
    backBackground.image = toVC.location.background;
    backBackground.frame = self.view.bounds;
    
    NSLog(@"Transitioning to %@", toVC.location.city);
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    WAWeatherVC *weatherVC = self.viewControllers[0];
    NSLog(@"Setting city from %@ to %@", self.location.city, weatherVC.location.city);
    self.location = weatherVC.location;
    if (completed) [self updateNavigationBar]; // fixes it.
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
    CGFloat x = scrollView.contentOffset.y / (568./100.);
    //NSLog(@"x: %f", x);
    
    // up or down?
    if (x > 100.) goingDown = YES;
    else goingDown = NO;

    // going down, so subtract from 200.
    if (x > 100.) x = 200. - x;
    
    background.alpha = x / 100.;
}

- (void)updateBackground {
    NSLog(@"Setting background.image to %@", self.location.city);
    background.image = self.location.background;
    background.frame = self.view.bounds;
}

@end
