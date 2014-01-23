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
    WAConditionDetailTVC *tvc = [[WAConditionDetailTVC alloc] initWithStyle:UITableViewStylePlain];
    tvc.location = self.location;
    [self.navigationController pushViewController:tvc animated:YES];
}

#pragma mark - Updates from WALocation

- (void)update {
    
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
    
    // feels like differs from actual.
    if (![self.location.temperature isEqualToString:self.location.feelsLike])
        self.feelsLikeLabel.text  = FMT(@"Feels like %@%@", self.location.feelsLike, self.location.tempUnit);
    else self.feelsLikeLabel.text = @"";

}

@end
