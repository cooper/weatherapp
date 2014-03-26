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
#import "WANavigationController.h"
#import "WAHourlyForecastTVC.h"

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
    self.view.backgroundColor = self.centeredView.backgroundColor = [UIColor clearColor];
    
    // add shadows.
    for (UILabel *label in @[
        self.temperature, self.conditionsLabel,
        self.locationTitle, self.feelsLikeLabel
    ]) [self addShadow:label radius:label == self.temperature ? 3.0 : 2.0];
    
    // make icon translucent so it's not too obnoxious.
    self.conditionsImageView.alpha = 0.8;
    
    // add tap gesture for menu.
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tempTapped)];
    [self.view addGestureRecognizer:recognizer];
    
    // add tap gesture for hourly.
    recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hourlyTapped)];
    [self.hourlyContainer addGestureRecognizer:recognizer];
    
    // update with current information.
    [self update];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self update];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!SETTING(kEnableHourlyPreviewSetting)) return;
    
    // fetch hourly forecast if that's enabled and we haven't already.
    if (!self.location.hourlyForecastResponse)
        [self.location fetchHourlyForecast:NO];
    
    // replace the hourly preview with snapshot if necessary.
    [self replaceHourlyWithSnapshot];
    
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    self.heightConstraint.constant = [UIScreen mainScreen].bounds.size.height - [UIApplication sharedApplication].statusBarFrame.size.height - appDelegate.nc.navigationBar.frame.size.height;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)addShadow:(UIView *)view radius:(CGFloat)radius {
    view.layer.shadowColor     = DARK_BLUE_COLOR.CGColor;
    view.layer.shadowOffset    = CGSizeMake(0, 0);
    view.layer.shadowRadius    = radius;
    view.layer.shadowOpacity   = 1.0;
    view.layer.shouldRasterize = YES;
}

#pragma mark - Interface actions

// anywhere tapped.
- (void)tempTapped {
    [appDelegate.pageVC titleTapped];
}

// hourly preview tapped.
- (void)hourlyTapped {

    // not enabled; treat this as a tap anywhere else
    if (!SETTING(kEnableHourlyPreviewSetting))
        return [self tempTapped];

    // load hourly view controller.
    if (!self.location.hourlyVC)
        self.location.hourlyVC = [[WAHourlyForecastTVC alloc] initWithLocation:self.location];
    
    [appDelegate.nc pushViewController:self.location.hourlyVC animated:YES];
}

#pragma mark - Updates from WALocation

- (void)animatedUpdate:(UILabel *)label newText:(NSString *)newText {

    // not visible. just do it.
    if (!self.isViewLoaded || !self.view.window) {
        label.text = newText;
        return;
    }

    // text hasn't changed.
    if ([newText isEqualToString:label.text]) return;
    
    // animate.
    [UIView animateWithDuration:0.5 animations:^{
        label.alpha = 0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5 animations:^{
            label.text  = newText;
            label.alpha = 1;
        }];
    }];
    
}

- (void)update {

    // info.
    [self animatedUpdate:self.locationTitle newText:self.location.city];
    [self animatedUpdate:self.conditionsLabel newText:self.location.conditions];
    
    // conditions icon.
    self.conditionsImageView.image = [UIImage imageNamed:FMT(@"icons/230/%@", self.location.conditionsImageName)];
    if (!self.conditionsImageView.image) self.conditionsImageView.image = self.location.conditionsImage;
    
    // localized temperature.
    [self animatedUpdate:self.temperature newText:self.location.temperature];
    
    // remote time.
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.timeZone   = self.location.timeZone;
    formatter.dateFormat = @"h:mm a";
    NSString *timeString = [formatter stringFromDate:self.location.observationsAsOf];

    // windchill, heat index, or other "feels like" temperature.
    NSString *feelsLike =
        self.location.windchillC != TEMP_NONE && ![self.location.temperature isEqualToString:self.location.windchill] ?
            FMT(@"Windchill %@", self.location.windchill)     :
        self.location.heatIndexC != TEMP_NONE && ![self.location.temperature isEqualToString:self.location.heatIndex] ?
            FMT(@"Heat index %@", self.location.heatIndex)    :
        ![self.location.temperature isEqualToString:self.location.feelsLike]                                          ?
            FMT(@"Feels like %@", self.location.feelsLike)    :
        nil;
    
    // display on the time if there is no "feels like."
    [self animatedUpdate:self.feelsLikeLabel newText:
        feelsLike ?
            FMT(@"%@  %@%@", timeString, feelsLike, self.location.tempUnit)
        : timeString
    ];

    // the rest of this is for hourly preview.
    if (!SETTING(kEnableHourlyPreviewSetting)) return;
    
    // nothing has changed.
    NSDate *laterDate = [self.location.hourlyForecastAsOf laterDate:lastHourlyPreviewUpdate];
    if (lastHourlyPreviewUpdate && laterDate == lastHourlyPreviewUpdate)
        return;
    
    // no data; fade out.
    NSArray *fiveHours = [self nextFiveHours];
    if (!fiveHours && self.hourlyContainer.alpha) [UIView animateWithDuration:0.5 animations:^{
        self.hourlyContainer.alpha = 0;
    }];
    
    // remove old views.
    [self.hourlyContainer.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    if (!fiveHours) return;
    NSLog(@"Updating hourly preview");
    
    // add new views.
    UInt8 i = 0;
    for (NSDictionary *hour in fiveHours) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(i * 64, 0, 64, 66)];
        
        // icon.
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(17, 0, 30, 30)];
        imageView.image = hour[@"iconImage"];
        [self addShadow:imageView radius:1.0];
        [view addSubview:imageView];
        
        // hour label.
        UILabel *hourLabel       = [[UILabel alloc] initWithFrame:CGRectMake(0, 27, 64, 18)];
        hourLabel.attributedText = hour[@"prettyHour"];
        hourLabel.textAlignment  = NSTextAlignmentCenter;
        hourLabel.textColor      = [UIColor whiteColor];
        hourLabel.font           = [UIFont systemFontOfSize:12];
        [self addShadow:hourLabel radius:1.0];
        [view addSubview:hourLabel];
        
        // temperature label.
        UILabel *tempLabel       = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, 64, 26)];
        tempLabel.text           = hour[@"temperature"];
        tempLabel.textAlignment  = NSTextAlignmentCenter;
        tempLabel.textColor      = [UIColor whiteColor];
        tempLabel.font           = [UIFont boldSystemFontOfSize:18];
        [self addShadow:tempLabel radius:1.0];
        [view addSubview:tempLabel];
        
        [self.hourlyContainer addSubview:view];
        i++;
    }
    
    // new data; fade in.
    if (fiveHours) [UIView animateWithDuration:0.5 animations:^{
        self.hourlyContainer.alpha = 1;
    } completion:^(BOOL finished) {
        [self replaceHourlyWithSnapshot];
    }];
    
    lastHourlyPreviewUpdate = [NSDate date];
}

#pragma mark - Hourly forecast preview

- (NSArray *)nextFiveHours {
    NSMutableArray *a = [NSMutableArray arrayWithCapacity:5];
    if (!self.location.hourlyForecastResponse) return nil;
    for (NSArray *day in self.location.hourlyForecast)
    for (id obj in day) {
        if ([a count] == 5) return a;
        
        // this is the day info array.
        if (![obj isKindOfClass:[NSDictionary class]]) continue;
        NSDictionary *hour = obj;
        
        [a addObject:hour];
    }
    return [a count] ? a : nil;
}

- (void)replaceHourlyWithSnapshot {

    // if the window is not set, there view is not visible.
    // this will be called again later after the view becomes visible
    // (in viewDidAppear)
    if (!self.isViewLoaded || !self.view.window) return;

    // never take a snapchat when the opacity is not 100%.
    if (self.hourlyContainer.alpha < 1) return;
    
    // if there are 1 or less subviews, I think we can assume we already did this.
    // the only case in which there would not be is if somehow only a single hour loaded.
    // that is not actually possible in the WeatherUnderground API as far as I am aware.
    if ([self.hourlyContainer.subviews count] <= 1) return;

    // lots of shadows are sometimes expensive, so after the animation completes,
    // replace all of these views with a single snapshot view.
    // this greatly improves the smoothness of swiping between locations.
    NSLog(@"Replacing hourly with snapshot");
    UIView *snapshot = [self.hourlyContainer snapshotViewAfterScreenUpdates:YES];
    
    // note: this property returns a copy of the subviews array, so there
    // is no need to copy it again here.
    NSArray *subviewsBefore = self.hourlyContainer.subviews;
    
    // take dimensions from hourly preview.
    snapshot.frame = CGRectMake(
        0, 0,
        self.hourlyContainer.frame.size.width, self.hourlyContainer.frame.size.height
    );
    
    // add the snapshot; then remove all other subviews.
    [self.hourlyContainer addSubview:snapshot];
    [subviewsBefore makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
}

@end
