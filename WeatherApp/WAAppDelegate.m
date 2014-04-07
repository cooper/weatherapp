//
//  WAAppDelegate.m
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/28/13.
//  Copyright (c) 2013-14 Mitchell Cooper. All rights reserved.
//

#import "WALocationManager.h"
#import "WALocation.h"
#import "WAWeatherVC.h"
#import "WANavigationController.h"
#import "WAPageViewController.h"
#import "WALocationListTVC.h"

WAAppDelegate     *appDelegate     = nil;
WALocationManager *locationManager = nil;

@implementation WAAppDelegate

#pragma mark - Application delegate

// app is almost done launching. this was first available in iOS 6.
- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    appDelegate = self;
    self.lastSettingsChange = [NSDate date];
    
    // set default options.
    [self setDefaults];
    
    // create location manager and load locations from user defaults.
    // fetch current conditions for favorite locations.
    locationManager = [WALocationManager new];
    [locationManager loadLocations:[DEFAULTS objectForKey:@"locations"]];
    [locationManager fetchLocations];
    
    // create the window and navigation controller.
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = TABLE_COLOR;
    self.window.rootViewController = self.navigationController = [[WANavigationController alloc] initWithMyRootController];
    
    // create the page view controller (used to scroll between overviews).
    self.pageViewController = [[WAPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationVertical options:@{ UIPageViewControllerOptionSpineLocationKey: @(UIPageViewControllerSpineLocationMid) }];
    self.pageViewController.dataSource = locationManager;
    
    // start iOS location services.
    [self startLocating];

    // rain notification background check (every thirty minutes or so).
    application.minimumBackgroundFetchInterval =
        SETTING(kEnableBackgroundSetting) ?
        1800 : UIApplicationBackgroundFetchIntervalNever;
    
    [self.window makeKeyAndVisible];
    return YES;
}

// this is called for the background app fetch functionality.
- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    NSLog(@"Background fetch!");
    
    // hasn't been 30 minutes since last fetch.
    if (abs([locationManager.currentLocation.conditionsAsOf timeIntervalSinceNow]) < 1800) {
        completionHandler(UIBackgroundFetchResultNoData);
        return;
    }
    
    // background fetch not enabled.
    if (!SETTING(kEnableBackgroundSetting)) {
        NSLog(@"Background fetch without setting enabled");
        completionHandler(UIBackgroundFetchResultFailed);
        return;
    }
    
    /*  here's how this works:

        let's say wunderground says chancerain
        show the notification with (as of) and set a bool that it's chancerain
        next time we update, if that bool is true, just ignore it.
        next time we update and it says it's not chancerain, set bool false.    */
    
    WALocation *location = locationManager.currentLocation;
    onFetchedConditions  = ^(NSURLResponse *res, NSDictionary *data) {

        BOOL rain = [location.conditionsImageName rangeOfString:@"rain"].location != NSNotFound;
        
        // chance of rain now, chance of rain before.
        if (rain && SETTING(kChanceRainKey)) {
            NSLog(@"Rain, but user already knows");
            completionHandler(UIBackgroundFetchResultNewData);
            return;
        }
        
        // chance of rain now, no chance before.
        if (rain && !SETTING(kChanceRainKey)) {
            NSLog(@"Rain");
            
            // notify the user.
            UILocalNotification *notification = [UILocalNotification new];
            notification.alertBody = @"Keep your umbrella handy!";
            [application scheduleLocalNotification:notification];
            
            [DEFAULTS setBool:YES forKey:kChanceRainKey];
        }
        
        // no chance of rain.
        else if (!rain && SETTING(kChanceRainKey)) {
            NSLog(@"No more rain");
            [DEFAULTS setBool:NO forKey:kChanceRainKey];
        }
        
        completionHandler(UIBackgroundFetchResultNewData);
        
    };
    
    gotLocation = NO;
    [self startLocating];
}

// application no longer active. update database.
- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self saveLocationsInDatabase];
}

// application closing. update database.
- (void)applicationWillTerminate:(UIApplication *)application {
    [self saveLocationsInDatabase];
}

#pragma mark - Location service management

// starts our location service.
- (void)startLocating {
    
    // create core location manager if we haven't already.
    if (!coreLocationManager) coreLocationManager = [CLLocationManager new];
    
    // set our desired accuracy.
    coreLocationManager.desiredAccuracy = kCLLocationAccuracyBest;
    coreLocationManager.delegate        = self;
    
    [coreLocationManager startUpdatingLocation];
    NSLog(@"Started location services");
    
}

// stop location services and fetch conditions.
- (void)stopLocating {

    // stop locating.
    NSLog(@"It's been 3 seconds since first location update; assuming accuracy is good enough");
    [coreLocationManager stopUpdatingLocation];
    NSLog(@"Stopped location services");

    // initial condition check.
    NSLog(@"Checking current conditions");
    [locationManager.currentLocation fetchCurrentConditions];
    [locationManager.currentLocation commitRequestThen:onFetchedConditions];
    
    // reset these for the next update.
    onFetchedConditions = nil;
    gotLocation         = NO;
    
}

#pragma mark - Activity indicator

// increase activity count.
- (void)beginActivity {
    activityCount++;
    if (activityCount) [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

// decrease activity count.
- (void)endActivity {
    if (activityCount > 0) activityCount--;
    if (!activityCount) [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark - CoreLocation manager delegate

// got a location update. set our current location object's coordinates.
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *recentLocation = [locations lastObject];
    
    // first update - start the ticker.
    if (!gotLocation) {
        gotLocation = YES;
        [self performSelector:@selector(stopLocating) withObject:nil afterDelay:3];
    }
    
    NSLog(@"Updating location: %f,%f", recentLocation.coordinate.latitude, recentLocation.coordinate.longitude);
    
    // set our current location.
    WALocation *loc  = locationManager.currentLocation;
    loc.latitude     = recentLocation.coordinate.latitude;
    loc.longitude    = recentLocation.coordinate.longitude;
    loc.locationAsOf = [NSDate date];

}

// core location error.
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Location error: %@", error);
    [self displayAlert:@"Location services error" message:error.localizedDescription];
}

// this is called when permissions to use core location change.
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status != kCLAuthorizationStatusAuthorized) return;
    
    // only start updating location if we're able to.
    if ([CLLocationManager locationServicesEnabled]) {
        [coreLocationManager startUpdatingLocation];
        NSLog(@"Location services enabled");
    }
    
}

#pragma mark - User defaults

// update the locations dictionary in database.
- (void)saveLocationsInDatabase {
    [DEFAULTS setObject:[locationManager locationsArrayForSaving] forKey:@"locations"];
    [DEFAULTS synchronize];
}

// set default options if we have not already done so.
- (void)setDefaults {
    
    // we already did this.
    if ([DEFAULTS boolForKey:@"set_default_options"]) return;
    
    // set default locations.
    [DEFAULTS setObject:@[
                          
        @{
            @"isCurrentLocation":   @YES
        },
        @{
            @"city":        @"Tokyo",
            @"region":      @"Japan",
            @"country3166": @"JP",
            @"countryCode": @"JP",
            @"conditions":  @"Mostly Cloudy",
            @"conditionsImageName": @"mostlycloudy",
            @"degreesF":    @70,
            @"degreesC":    @20
        },
        @{
            @"city":        @"Los Angeles",
            @"region":      @"California",
            @"country3166": @"US",
            @"countryCode": @"US",
            @"conditions":  @"Clear",
            @"conditionsImageName": @"clear",
            @"degreesF":    @75,
            @"degreesC":    @22
        }
        
    ] forKey:@"locations"];
    
    // set default preferences.
    [DEFAULTS setObject:kTemperatureScaleFahrenheit forKey:kTemperatureScaleSetting];
    [DEFAULTS setObject:kDistanceMeasureMiles       forKey:kDistanceMeasureSetting];
    [DEFAULTS setObject:kPrecipitationMeasureInches forKey:kPrecipitationMeasureSetting];
    [DEFAULTS setObject:kPressureMeasureInchHg      forKey:kPressureMeasureSetting];
    [DEFAULTS setObject:kTimeZoneRemote             forKey:kTimeZoneSetting];
    
    // default booleans.
    [DEFAULTS setBool:YES forKey:kEnableBackgroundSetting];
    [DEFAULTS setBool:YES forKey:kEnableHourlyPreviewSetting];
    //[DEFAULTS setBool:NO  forKey:kEnableFullLocationNameSetting];
    
    [DEFAULTS setObject:@{} forKey:@"backgrounds"];
    
    // remember that we set these values.
    [DEFAULTS setBool:YES forKey:@"set_default_options"];
    
}

#pragma mark - Convenience

// display a UIAlert without a delegate.
- (void)displayAlert:(NSString *)title message:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alert show];
}

// safely returns a float of an objective temperature value.
float temp_safe(id temp) {
    float floatValue = [temp floatValue];
    
    // this is a number, which makes things easy.
    if ([temp isKindOfClass:[NSNumber class]]) {
        if (floatValue < -200)
            return TEMP_NONE;
        return floatValue;
    }
    
    // otherwise, strings are a bit more tricky.
    NSString *tempStr = temp;
    
    // empty string = no temperature.
    if ([tempStr length] == 0)
        return TEMP_NONE;
    
    // if it's more than 1 character, it can't be zero numerically.
    // (unless they did something really silly like "0.", but I haven't seen that)
    if ([tempStr length] > 1) {
        if (floatValue == 0 || floatValue < -200)
            return TEMP_NONE;
        return floatValue;
    }
    
    // if it's only 1 character, it's hopefully a single-digit number.
    return floatValue;
    
}

@end
