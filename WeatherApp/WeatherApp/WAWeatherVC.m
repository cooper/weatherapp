//
//  WAWeatherController.m
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/28/13.
//  Copyright (c) 2013 Really Good. All rights reserved.
//

#import "WAWeatherVC.h"
#import "WALocation.h"

@interface WAWeatherVC ()

@end

@implementation WAWeatherVC

#pragma mark - View controller

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = TABLE_COLOR;
    refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshButtonTapped)];
    self.navigationItem.rightBarButtonItem = refreshButton;
    
    // re-enable edge drag gesture.

}

- (void)viewWillAppear:(BOOL)animated {
    //self.navigationController.navigationBar.tintColor    = BLUE_COLOR;]
    //self.navigationController.navigationBar.barTintColor = [UIColor clearColor];
    if (self.location)
        [self updateTemperature:self.location.degreesC fahrenheit:self.location.degreesF];

    //[self.navigationController setNavigationBarHidden:YES animated:animated];
    self.navigationController.interactivePopGestureRecognizer.delegate = self;

}

- (void)viewDidAppear:(BOOL)animated {

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)refreshButtonTapped {
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [indicator startAnimating];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:indicator];
    [self.navigationItem setRightBarButtonItem:item animated:YES];
    [self.location fetchCurrentConditionsThen:^{
        if (refreshButton) [self.navigationItem setRightBarButtonItem:refreshButton animated:YES];
    }];
}

#pragma mark - Updates from WALocation

// update the current location (city) title.
- (void)updateLocationTitle:(NSString *)title {
    self.navigationItem.title =
    self.locationTitle.text = title;
}

// update the region; the state or country (outside of US).
- (void)updateRegionTitle:(NSString *)title {
    self.fullLocationLabel.text = FMT(@"%@, %@", self.locationTitle.text, title);
}

// update the current temperature.
- (void)updateTemperature:(float)metric fahrenheit:(float)fahrenheit {
    if ([[DEFAULTS objectForKey:@"Temperature scale"] isEqualToString:@"Fahrenheit"])
        self.temperature.text = [NSString stringWithFormat:@"%.f", fahrenheit];
    else if ([[DEFAULTS objectForKey:@"Temperature scale"] isEqualToString:@"Celsius"])
        self.temperature.text = [NSString stringWithFormat:@"%.f", metric];
    else if ([[DEFAULTS objectForKey:@"Temperature scale"] isEqualToString:@"Kelvin"])
        self.temperature.text = [NSString stringWithFormat:@"%.f", metric + 273.15];
}

- (void)updateFullTitle:(NSString *)title {
    self.fullLocationLabel.text = title;
}

- (void)updateLatitude:(float)latitude longitude:(float)longitude {
    self.coordinateLabel.text = FMT(@"%f,%f", latitude, longitude);
}

- (void)updateConditions:(NSString *)conditions {
    self.conditionsLabel.text = conditions;
}

@end
