//
//  WAWeatherVC.m
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/28/13.
//  Copyright (c) 2013-14 Mitchell Cooper. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "WAWeatherVC.h"
#import "WALocation.h"
#import "WAPageViewController.h"

@implementation WAWeatherVC

- (id)initWithLocation:(WALocation *)location {
    self = [self initWithNibName:@"WAWeatherVC" bundle:nil];
    if (self) self.location = location;
    return self;
}

#pragma mark - View controller

- (void)viewDidLoad {
    [super viewDidLoad];

    // clear because background's on page controller.
    self.view.backgroundColor  = [UIColor clearColor];
    
    // add shadows.
    for (UILabel *label in @[
        self.temperature, self.conditionsLabel,
        self.locationTitle, self.coordinateLabel,
        self.regionLabel, self.feelsLikeLabel
    ]) {
        label.layer.shadowColor     = [UIColor blackColor].CGColor;
        label.layer.shadowOffset    = CGSizeMake(0, 0);
        label.layer.shadowRadius    = label == self.temperature ? 3.0 : 2.0;
        label.layer.shadowOpacity   = 1.0;
        label.layer.masksToBounds   = NO;
        label.layer.shouldRasterize = YES;
    }
    
    // make icon translucent so it's not too obnoxious.
    self.conditionsImageView.alpha = 0.8;
    
    // add tap gesture.
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tempTapped)];
    [self.view addGestureRecognizer:recognizer];
    
    // update with current information.
    [self update];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [self update];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Interface actions

- (void)tempTapped {
    [appDelegate.pageVC titleTapped];
}

#pragma mark - Updates from WALocation

- (void)update {

    // info.
    self.locationTitle.text     = self.location.city;
    self.regionLabel.text       = self.location.region;
    self.coordinateLabel.text   = FMT(@"%f,%f", self.location.latitude, self.location.longitude);
    self.conditionsLabel.text   = self.location.conditions;
    
    // conditions icon.
    self.conditionsImageView.image = [UIImage imageNamed:FMT(@"icons/230/%@", self.location.conditionsImageName)];
    if (!self.conditionsImageView.image) self.conditionsImageView.image = self.location.conditionsImage;
    
    // localized temperature.
    self.temperature.text = self.location.temperature;
    
    // windchill, heat index, or other "feels like" temperature.
    self.feelsLikeLabel.text =
        self.location.windchillC != TEMP_NONE && ![self.location.temperature isEqualToString:self.location.windchill] ?
            FMT(@"Windchill %@%@", self.location.windchill, self.location.tempUnit)     :
        self.location.heatIndexC != TEMP_NONE && ![self.location.temperature isEqualToString:self.location.heatIndex] ?
            FMT(@"Heat index %@%@", self.location.heatIndex, self.location.tempUnit)    :
        ![self.location.temperature isEqualToString:self.location.feelsLike]            ?
            FMT(@"Feels like %@%@", self.location.feelsLike, self.location.tempUnit)    :
        @"";

    // hide labels if necessary.
    self.coordinateLabel.alpha = SETTING(kEnableLongitudeLatitudeSetting) ? 1 : 0;
    self.regionLabel.alpha     = SETTING(kEnableFullLocationNameSetting ) ? 1 : 0;
    
}

@end
