//
//  WAPageViewController.m
//  Weather
//
//  Created by Mitchell Cooper on 12/19/13.
//  Copyright (c) 2013-14 Mitchell Cooper. All rights reserved.
//

#import "WAPageViewController.h"
#import "WALocation.h"
#import "WALocationManager.h"
#import "WANavigationController.h"
#import "Fade/UINavigationController+Fade.h"

#import "WAWeatherVC.h"
#import "WAConditionDetailTVC.h"
#import "WADailyForecastTVC.h"
#import "WAHourlyForecastTVC.h"
#import "WAPageViewController.h"

@implementation WAPageViewController

@synthesize background = background;

#pragma mark - Page view controller

- (id)initWithTransitionStyle:(UIPageViewControllerTransitionStyle)style navigationOrientation:(UIPageViewControllerNavigationOrientation)navigationOrientation options:(NSDictionary *)options {
    self = [super initWithTransitionStyle:style navigationOrientation:navigationOrientation options:options];
    if (self) self.delegate = self; // this is a looping reference, but we'll never destroy the page VC anyway.
    return self;
}

- (void)setViewController:(WAWeatherVC *)weatherVC {
    [appDelegate.pageVC setViewControllers:@[weatherVC] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    self.location = weatherVC.location;
    [self updateNavigationBar];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // create the menu.
    menu = [[DIYMenu alloc] initWithFrame:self.view.window.bounds];
    menu.delegate = self;
    
    // many different shades of blue.
    UIColor *c_0 = [UIColor colorWithRed:       0  green: 70./255. blue:200./255. alpha:1];
    UIColor *c_1 = [UIColor colorWithRed: 43./255. green:101./255. blue:236./255. alpha:1];
    UIColor *c_2 = [UIColor colorWithRed: 21./255. green:137./255. blue:       1  alpha:1];
    UIColor *c_3 = [UIColor colorWithRed: 56./255. green:172./255. blue:236./255. alpha:1];
    UIColor *c_4 = [UIColor colorWithRed:130./255. green:202./255. blue:       1  alpha:1];
    
    // add the menu items.
    UIFont *font = [UIFont systemFontOfSize:25];
    [menu addItem:@"Location list"     withGlyph:@"🌎" withColor:c_0 withFont:font withGlyphFont:font];
    [menu addItem:@"Current overview"  withGlyph:@"⛅️" withColor:c_1 withFont:font withGlyphFont:font];
    [menu addItem:@"Extensive details" withGlyph:@"📝" withColor:c_2 withFont:font withGlyphFont:font];
    [menu addItem:@"Hourly forecast"   withGlyph:@"🕓" withColor:c_3 withFont:font withGlyphFont:font];
    [menu addItem:@"Daily forecast"    withGlyph:@"📅" withColor:c_4 withFont:font withGlyphFont:font];

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
    [super viewWillAppear:animated];
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
    
    // if the hourly exists, reload that too for the preview.
    if (self.location.hourlyForecastResponse)
        [self.location fetchHourlyForecast:NO];
    
}

// display the menu.
- (void)titleTapped {
    ((DIYMenuItem *)menu.menuItems[1]).name.text = FMT(@"%@ overview", self.location.city);
    [menu showMenu];
}

#pragma mark - Menu

- (void)menuItemSelected:(NSString *)action {
    UIViewController *vc;

    if ([action isEqualToString:@"Location list"]) {
        [appDelegate.nc popToRootViewControllerAnimated:YES];
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
    
    // already on this view controller.
    if (vc == appDelegate.nc.topViewController) return;
    
    // for the overview, just pop back to the page view controller.
    if (vc == self) {
        [appDelegate.nc popToViewController:self animated:YES];
        return;
    }

    // then move on to the selection.
    // if the current top vc is the overview, push to it.
    // if it's something else, use the fade transition to avoid confusion.
    if (appDelegate.nc.topViewController == self) {
        [appDelegate.nc pushViewController:vc animated:YES];
    }
    else {
        [appDelegate.nc popViewControllerAnimated:NO];
        [appDelegate.nc pushFadeViewController:vc];
    }
    
}

- (UILabel *)menuLabelWithTitle:(NSString *)title {
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    UITapGestureRecognizer *tap       = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(titleTapped)];
    titleLabel.userInteractionEnabled = YES;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor     = [UIColor whiteColor];
    titleLabel.font          = [UIFont boldSystemFontOfSize:17];
    titleLabel.text          = title;
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
