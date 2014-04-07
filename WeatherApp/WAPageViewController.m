//
//  WAPageViewController.m
//  Weather
//
//  Created by Mitchell Cooper on 12/19/13.
//  Copyright (c) 2013-14 Mitchell Cooper. All rights reserved.
//

#import "WALocation.h"
#import "WALocationManager.h"

#import "WANavigationController.h"
#import "WAPageViewController.h"

#import "WAWeatherVC.h"
#import "WAConditionDetailTVC.h"
#import "WADailyForecastTVC.h"
#import "WAHourlyForecastTVC.h"

#import "UINavigationController+Fade.h"
#import "UIImage+WhiteImage.h"

#import "WAMenu/WAMenuItem.h"

@implementation WAPageViewController

#pragma mark - Page view controller

- (instancetype)initWithTransitionStyle:(UIPageViewControllerTransitionStyle)style navigationOrientation:(UIPageViewControllerNavigationOrientation)navigationOrientation options:(NSDictionary *)options {
    self = [super initWithTransitionStyle:style navigationOrientation:navigationOrientation options:options];
    
    // this is a looping reference - I am aware.
    // however, this object will never be destroyed from start to exit of the application,
    // so the hanging refcount does not actually matter at all.
    if (self) self.delegate = self;
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // create the menu.
    menu = [[WAMenu alloc] initWithFrame:self.view.window.bounds];
    menu.delegate = self;
    
    // many different shades of blue.
    UIColor *c_0 = RGBA(  0.,  70., 200., 1);
    UIColor *c_1 = RGBA( 43., 101., 236., 1);
    UIColor *c_2 = RGBA( 21., 137., 255., 1);
    UIColor *c_3 = RGBA( 56., 172., 236., 1);
    UIColor *c_4 = RGBA(130., 202., 255., 1);
    
    // add the menu items.
    UIFont *font   = [UIFont systemFontOfSize:25];
    NSArray *items = @[
        @[@"Location list",     @"list",    c_0],
        @[@"Current overview",  @"",        c_1],
        @[@"Extensive details", @"details", c_2],
        @[@"Hourly forecast",   @"hourly",  c_3],
        @[@"Daily forecast",    @"daily",   c_4]
    ];
    for (NSArray *item in items) {
        UIImage *icon   = [UIImage imageNamed:FMT(@"icons/menu/%@", item[1])];
        if (!icon) icon = [UIImage imageNamed:@"icons/30/clear"];
        [menu addItem:item[0] icon:icon color:item[2] font:font];
    }

    // this fixes the navigation bar inset issue.
    // however, it causes the page view controller to ignore the navigation bar completely
    // (so its frame goes behind the navigation bar as well.)
    self.automaticallyAdjustsScrollViewInsets = NO;
        
    self.view.backgroundColor      = [UIColor clearColor];
    self.view.multipleTouchEnabled = NO;
    
    // custom title view with gesture recognizer for menu.
    self.navigationItem.titleView = [self menuLabelWithTitle:@"Overview"];
    
    // refresh button.
    refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshButtonTapped)];
    self.navigationItem.rightBarButtonItem = refreshButton;
    
    // remove the text on the back button.
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    // scroll view delegate.
    [self.view.subviews[0] setDelegate:self];
    
    // from background.
    background = [[UIImageView alloc] initWithFrame:self.view.bounds];
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
    [super viewWillAppear:animated];
}

#pragma mark - Page view controller delegate

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers {
    WAWeatherVC *toVC = pendingViewControllers[0];
    NSUInteger i      = goingDown ? toVC.location.index - 1 : toVC.location.index + 1;
    
    // set the forebackground to the location we were on already.
    WALocation *locationBefore = locationManager.locations[i];
    background.image = locationBefore.background;
    background.frame = self.view.bounds;
    
    // set the backbackground to that of the upcoming location.
    backBackground.image = toVC.location.background;
    backBackground.frame = self.view.bounds;
    
    NSLog(@"Transitioning to %@", toVC.location.city);
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    WAWeatherVC *weatherVC = self.viewControllers[0];

    // update the current location.
    NSLog(@"Setting current city from %@ to %@", self.location.city, weatherVC.location.city);
    self.location = weatherVC.location;

    // update the navigation bar and background only if the user lets go.
    if (completed) [self updateNavigationBar]; // fixes it.
    
}

#pragma mark - Update information

// set the current weather view controller, updating location and navigation bar.
- (void)setViewController:(WAWeatherVC *)weatherVC {
    [appDelegate.pageViewController setViewControllers:@[weatherVC] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    self.location = weatherVC.location;
    [self updateNavigationBar];
}

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
    if (background.image != self.location.background)
        background.image = self.location.background;
    background.frame = self.view.bounds;
}

#pragma mark - Interface actions

// update conditions.
- (void)refreshButtonTapped {
    [self.location fetchCurrentConditions];
    
    // if the hourly exists, reload that too for the preview.
    if (self.location.hourlyForecastResponse)
        [self.location fetchHourlyForecast:NO];
    
    [self.location commitRequest];
}

// display the menu.
- (void)titleTapped {
    WAMenuItem *item = menu.menuItems[1];
    item.name.text = FMT(@"%@ overview", self.location.city);
    UIImageView *iconView = (UIImageView *)[item viewWithTag:10];
    iconView.image = [UIImage imageNamed:FMT(@"icons/30/%@", self.location.conditionsImageName)];
    iconView.image = [iconView.image whiteImage];
    [menu showMenu];
}

#pragma mark - Menu

- (void)menuItemSelected:(NSString *)action {
    WANavigationController *navigationController = appDelegate.navigationController;
    UIViewController *vc;

    // decide which item was selected.

    if ([action isEqualToString:@"Location list"]) {
        [navigationController popToRootViewControllerAnimated:YES];
        return;
    }
    else if ([action rangeOfString:@"overview"].location != NSNotFound) {
        vc = self;
    }
    else if ([action isEqualToString:@"Extensive details"]) {
        if (!self.location.detailVC)
            self.location.detailVC = [[WAConditionDetailTVC alloc] initWithLocation:self.location];
        vc = self.location.detailVC;
    }
    else if ([action isEqualToString:@"Hourly forecast"]) {
        if (!self.location.hourlyVC)
            self.location.hourlyVC = [[WAHourlyForecastTVC alloc] initWithLocation:self.location];
        vc = self.location.hourlyVC;
    }
    else if ([action isEqualToString:@"Daily forecast"]) {
        if (!self.location.dailyVC)
            self.location.dailyVC = [[WADailyForecastTVC alloc] initWithLocation:self.location];
        vc = self.location.dailyVC;
    }
    else return;
    
    // we're already on this view controller.
    if (vc == navigationController.topViewController) return;
    
    // for the overview, just pop back to the page view controller (self).
    if (vc == self) {
        [navigationController popToViewController:self animated:YES];
        return;
    }

    // then move on to the selection.
    // if the current top vc is the overview, push to it.
    // if it's something else, use the fade transition to avoid confusion.
    if (navigationController.topViewController == self) {
        [navigationController pushViewController:vc animated:YES];
    }
    else {
        [navigationController popViewControllerAnimated:NO];
        [navigationController pushFadeViewController:vc];
    }
    
}

// create a UILabel with a gesture recognizer to show the menu.
// this is used across the different weather data view controllers.
- (UILabel *)menuLabelWithTitle:(NSString *)title {

    // create a label of the appropriate dimensions.
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    titleLabel.userInteractionEnabled = YES;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor     = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:17];
    titleLabel.text = title;
    
    // add gesture recognizer.
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(titleTapped)];
    [titleLabel addGestureRecognizer:tap];
    
    return titleLabel;
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
