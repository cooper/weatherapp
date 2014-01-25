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
    coreLocationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    coreLocationManager.distanceFilter  = 100;
    coreLocationManager.delegate        = self;
    
    [coreLocationManager startUpdatingLocation];
    NSLog(@"Started location services");
    
}

- (void)stopLocating {
    
    // if it's been less than 5 seconds since the last lookup, don't do it.
    // this is just extra protection against wunderground's API limits.
    if (self.currentLocation.conditionsAsOf &&
        [self.currentLocation.conditionsAsOf timeIntervalSinceNow] > -5.) {
        NSLog(@"Just looked up less than 5 seconds ago. Not doing it again");
        return;
    }
    
    // initial condition check.
    // checked again after 5 seconds of no location updates.
    NSLog(@"Checking current conditions initially");
    [self.currentLocation fetchCurrentConditions];
    initialTime = self.currentLocation.locationAsOf;
    
    // quit locating if necessary.
    [self performSelector:@selector(checkIfDoneLocating) withObject:nil afterDelay:5];
    
}

// timed-out method checks if location hasn't been updated for 5 seconds
// or more and disables location services if it has.
- (void)checkIfDoneLocating {
    NSLog(@"Checking if we're done locating");

    // it has updated recently.
    if ([self.currentLocation.locationAsOf timeIntervalSinceNow] > -2) {
        NSLog(@"Received an update within last 2 seconds; waiting 3 more.");
        
        // check again in 3 more seconds.
        [self performSelector:@selector(checkIfDoneLocating) withObject:nil afterDelay:3];
        return;
        
    }
    
    // it has been. stop updating the location.
    NSLog(@"Stopping location services");
    [coreLocationManager stopUpdatingLocation];
    
    // nothing changed.
    if ([initialTime isEqualToDate:self.currentLocation.locationAsOf]) {
        NSLog(@"Location has not changed");
        return;
    }
    
    // the location did change.
    NSLog(@"Location has changed. Fetching current conditions with updated location");
    [self.currentLocation fetchCurrentConditions];
    
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
        
        // initial lookup after 3 seconds.
        [self performSelector:@selector(stopLocating) withObject:nil afterDelay:3];
        
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
    
    [DEFAULTS setObject:@{} forKey:@"backgrounds"];
    
    // remember that we set these values.
    [DEFAULTS setBool:YES forKey:@"set_default_options"];
    
}

@end
