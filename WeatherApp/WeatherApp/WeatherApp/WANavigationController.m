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

    // make bar transparent.
    [self.navigationBar setBackgroundImage:[UIImage imageNamed:@"navbar"] forBarMetrics:UIBarMetricsDefault];

//    [self.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    
//    // create navigation bar shadow.
//    bar.layer.shadowRadius    = 1.0;
//    bar.layer.shadowOpacity   = 1.0;
//    bar.layer.shadowOffset    = CGSizeMake(0, 0);
//    bar.layer.shadowColor     = [UIColor blackColor].CGColor;
//    bar.layer.shouldRasterize = YES;
//    
//    
//    
//    // other navbar appearance settings.
//    bar.shadowImage = [UIImage new];
    bar.translucent = YES;
    bar.tintColor   = [UIColor whiteColor];
    bar.titleTextAttributes = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    

    
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

//#pragma mark - Scroll views
//
//
//- (void)scrollView:(UIScrollView *)scrollView didScrollTo:(CGPoint)point {
//    return;
//    BOOL atTop = point.y + scrollView.contentInset.top <= 5;
//    if ( atTop && self.navigationBar.alpha == 1) return;
//    if (!atTop && self.navigationBar.alpha == 0) return;
//    [UIView animateWithDuration:0.2 animations:^{
//        if (atTop) self.navigationBar.alpha = 1;
//        else self.navigationBar.alpha = 0;
//    }];
//}

@end
