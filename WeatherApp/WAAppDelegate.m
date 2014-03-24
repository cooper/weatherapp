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

WAAppDelegate *appDelegate = nil;

@implementation WAAppDelegate

#pragma mark - Application delegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    appDelegate = self;
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = TABLE_COLOR;

    // set default options if we haven't already.
    [self setDefaults];
    
    // load locations from settings.
    self.locationManager = [WALocationManager new];
    [self.locationManager loadLocations:[DEFAULTS objectForKey:@"locations"]];
    [self.locationManager fetchLocations];
    
    // create the navigation controller.
    self.window.rootViewController = self.nc = [[WANavigationController alloc] initWithMyRootController];
    
    // create the page view controller.
    self.pageVC = [[WAPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationVertical options:@{ UIPageViewControllerOptionSpineLocationKey: @(UIPageViewControllerSpineLocationMid) }];
    self.pageVC.dataSource = self.locationManager;
    
    // start locating.
    [self startLocating];

    // rain notification background check (every thirty minutes at most).
    application.minimumBackgroundFetchInterval =
        SETTING(kEnableBackgroundSetting) ?
        1800 : UIApplicationBackgroundFetchIntervalNever;
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    NSLog(@"Background fetch!");
    
    // background fetch not enabled.
    if (!SETTING(kEnableBackgroundSetting)) {
        NSLog(@"Background fetch without setting enabled");
        completionHandler(UIBackgroundFetchResultFailed);
        return;
    }
    
    // here's how this works:
    /*
    
        let's say wunderground says chancerain
        show the notification with (as of) and set a bool that it's chancerain
        
        next time we update, if that bool is true, just ignore it.
     
        next time we update and it says it's not chancerain, set bool false.
    
    */
    
    WALocation *location = self.currentLocation;
    
    onFetchedConditions = ^{

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

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self saveLocationsInDatabase];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self saveLocationsInDatabase];
}

#pragma mark - Location service management

- (WALocation *)currentLocation {
    return self.locationManager.currentLocation;
}

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

- (void)stopLocating {

    // stop locating.
    NSLog(@"It's been 3 seconds since first location update; assuming accuracy is good enough");
    [coreLocationManager stopUpdatingLocation];
    NSLog(@"Stopped location services");

    // initial condition check.
    NSLog(@"Checking current conditions");
    [self.currentLocation fetchCurrentConditionsThen:onFetchedConditions];
    
    // reset these for the next update.
    onFetchedConditions = nil;
    gotLocation         = NO;
    
}

#pragma mark - Activity

- (void)beginActivity {
    activityCount++;
    if (activityCount) [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)endActivity {
    activityCount--;
    if (!activityCount) [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark - Core location manager delegate

// got a location update. set our current location object's coordinates.
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *recentLocation = [locations lastObject];
    
    // first update - start the ticker.
    if (!gotLocation) [self performSelector:@selector(stopLocating) withObject:nil afterDelay:3];
    
    NSLog(@"Updating location: %f,%f", recentLocation.coordinate.latitude, recentLocation.coordinate.longitude);
    
    // set our current location.
    self.currentLocation.latitude     = recentLocation.coordinate.latitude;
    self.currentLocation.longitude    = recentLocation.coordinate.longitude;
    self.currentLocation.locationAsOf = [NSDate date];
    
    gotLocation = YES;

}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager {
    NSLog(@"Resumed location updates");
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Location error: %@", error);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location services error" message:[error localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alert show];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status != kCLAuthorizationStatusAuthorized) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location permissions" message:@"Please enable location services for this app in the Settings app." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
        return;
    }
    
    // only start updating location if we're able to.
    if ([CLLocationManager locationServicesEnabled]) {
        [coreLocationManager startUpdatingLocation];
        NSLog(@"Location services enabled");
    }
    
}

#pragma mark - User defaults

- (void)saveLocationsInDatabase {
    [DEFAULTS setObject:[self.locationManager locationsArrayForSaving] forKey:@"locations"];
    [DEFAULTS synchronize];
}

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
    [DEFAULTS setObject:kPercipitationMeasureInches forKey:kPercipitationMeasureSetting];
    [DEFAULTS setObject:kTimeZoneRemote             forKey:kTimeZoneSetting];
    
    // default booleans.
    [DEFAULTS setBool:YES forKey:kEnableBackgroundSetting];
    [DEFAULTS setBool:NO  forKey:kEnableFullLocationNameSetting];
    [DEFAULTS setBool:NO  forKey:kEnableLongitudeLatitudeSetting];
    
    [DEFAULTS setObject:@{} forKey:@"backgrounds"];
    
    // remember that we set these values.
    [DEFAULTS setBool:YES forKey:@"set_default_options"];
    
}

@end
