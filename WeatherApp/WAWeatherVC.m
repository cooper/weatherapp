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
#import "WAConditionDetailTVC.h"

@implementation WAWeatherVC

#pragma mark - View controller

- (void)viewDidLoad {
    [super viewDidLoad];

    // clear because background's on page controller.
    self.view.backgroundColor  = [UIColor clearColor];
    
    // add shadows.
    for (UILabel *label in @[
        self.temperature, self.conditionsLabel,
        self.locationTitle, self.coordinateLabel,
        self.fullLocationLabel, self.feelsLikeLabel
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
    [self updateInterface];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [self updateInterface];
    if (detailTVC) detailTVC = nil;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Interface actions

- (void)tempTapped {

    // no forecast fetched yet; do so.
    if (!self.location.forecast)
        [self.location fetchForecast];

    // load the forecast view controller.
    detailTVC = [[WAConditionDetailTVC alloc] initWithLocation:self.location];
    
    // push.
    [self.navigationController pushViewController:detailTVC animated:YES];
    
}

#pragma mark - Updates from WALocation

- (void)update {
    [self updateInterface];
    if (detailTVC) [detailTVC update];
}

- (void)updateInterface {
    
    // info.
    self.locationTitle.text     = self.location.city;
    self.fullLocationLabel.text = self.location.fullName;
    self.coordinateLabel.text   = FMT(@"%f,%f", self.location.latitude, self.location.longitude);
    self.conditionsLabel.text   = self.location.conditions;
    
    // conditions icon.
    self.conditionsImageView.image = [UIImage imageNamed:FMT(@"icons/230/%@", self.location.conditionsImageName)];
    if (!self.conditionsImageView.image) self.conditionsImageView.image = self.location.conditionsImage;
    
    // localized temperature.
    self.temperature.text = self.location.temperature;
    
    // feels like, windchill, and heat index.
    if (self.location.windchillC != TEMP_NONE)
        self.feelsLikeLabel.text = FMT(@"Windchill %@%@", self.location.windchill, self.location.tempUnit);
    else if (self.location.heatIndexC != TEMP_NONE)
        self.feelsLikeLabel.text = FMT(@"Heat index %@%@", self.location.heatIndex, self.location.tempUnit);
    else if (![self.location.temperature isEqualToString:self.location.feelsLike])
        self.feelsLikeLabel.text  = FMT(@"Feels like %@%@", self.location.feelsLike, self.location.tempUnit);
    else self.feelsLikeLabel.text = @"";

    // hide labels if necessary.
    self.coordinateLabel.alpha   = SETTING(kEnableLongitudeLatitudeSetting) ? 1 : 0;
    self.fullLocationLabel.alpha = SETTING(kEnableFullLocationNameSetting ) ? 1 : 0;
    
}

@end
