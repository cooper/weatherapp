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

@implementation WAAppDelegate

#pragma mark - Application delegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = TABLE_COLOR;
    
    // create the location manager and current location view controller.
    self.locationManager = [[WALocationManager alloc] init];

    // set default options if we haven't already.
    [self setDefaults];
    
    // load locations from settings.
    [self.locationManager loadLocations:[DEFAULTS objectForKey:@"locations"]];
    [self.locationManager fetchLocations];
    
    // create the navigation controller.
    self.window.rootViewController = self.nc = [[WANavigationController alloc] initWithMyRootController];
    
    // create the page view controller.
    self.pageVC = [[WAPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationVertical options:@{ UIPageViewControllerOptionSpineLocationKey: @(UIPageViewControllerSpineLocationMid) }];
    self.pageVC.dataSource = self.locationManager;
    
    // start locating.
    [self startLocating];

    [self.window makeKeyAndVisible];
    return YES;
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
    if (!coreLocationManager) coreLocationManager = [[CLLocationManager alloc] init];
    
    // set our desired accuracy.
    coreLocationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    coreLocationManager.distanceFilter  = 1000; // only notify when change is 1000 meters or more
    coreLocationManager.delegate        = self;
    [coreLocationManager startUpdatingLocation];

    NSLog(@"basically started");
    
}

- (void)stopLocating {
    NSLog(@"assuming accuracy is good enough");
    
    // FIXME: this currently just stops locating.
    // maybe I should implement refreshing eventually.
    [coreLocationManager stopUpdatingLocation];
    
    // fetch the current conditions if location was found
    // FIXME: what is latitude is 0? chances are slim, but that's still valid...
    if (self.currentLocation.latitude) [self.currentLocation fetchCurrentConditions];
    
}

#pragma mark - For use anywhere

- (void)saveLocationsInDatabase {
    [DEFAULTS setObject:[self.locationManager locationsArrayForSaving] forKey:@"locations"];
}

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
    NSLog(@"updating location: %f,%f", recentLocation.coordinate.latitude, recentLocation.coordinate.longitude);
    
    // set our current location.
    self.currentLocation.latitude     = recentLocation.coordinate.latitude;
    self.currentLocation.longitude    = recentLocation.coordinate.longitude;
    self.currentLocation.locationAsOf = [NSDate date];
    
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager {
    NSLog(@"resumed location updates");
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"location error: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status != kCLAuthorizationStatusAuthorized) return;
    // only start updating location if we're able to.
    if ([CLLocationManager locationServicesEnabled]) {
        [coreLocationManager startUpdatingLocation];
        [self performSelector:@selector(stopLocating) withObject:nil afterDelay:3];
        NSLog(@"enabled!");
    }
}

#pragma mark - App management

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
    
    [DEFAULTS setObject:@{} forKey:@"backgrounds"];
    
    // remember that we set these values.
    [DEFAULTS setBool:YES forKey:@"set_default_options"];
    
}

@end
