//
//  WAAppDelegate.m
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/28/13.
//  Copyright (c) 2013 Really Good. All rights reserved.
//

#import "WAAppDelegate.h"
#import "WALocationManager.h"
#import "WALocation.h"
#import "WAWeatherVC.h"
#import "WANavigationController.h"

@implementation WAAppDelegate

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor blackColor];
    
    // create the location manager and current location view controller.
    locationManager = [[WALocationManager alloc] init];
    currentLocation = [locationManager createLocation]; // index always 0
    currentLocation.isCurrentLocation = YES;
    
    // FIXME: temporary hard-coded settings.
    if (![DEFAULTS boolForKey:@"set_default_locations"]) {
        [DEFAULTS setObject:@{
            @"1": @{
                @"city": @"New York",
                @"stateShort": @"NY"
            },
            @"2": @{
                @"city": @"Mumbai",
                @"country": @"India"
            }
        } forKey:@"locations"];
        [DEFAULTS setBool:YES forKey:@"set_default_locations"];
    }
    
    // load locations from settings.
    [locationManager loadLocations:[DEFAULTS objectForKey:@"locations"]];
    [locationManager fetchLocations];
    
    // create the page view controller.
    self.window.rootViewController = pageVC = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationDirectionForward options:nil];
    
    // set the data source to our location manager and set the current
    // view controller list to contain the initial view controller.
    pageVC.dataSource = locationManager;
    [pageVC setViewControllers:@[currentLocation.viewController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    
    
    // create the navigation controller.
    self.nc = [[WANavigationController alloc] initWithMyRootController];
    
    // start locating.
    [self startLocating];

    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Location service management

// starts our location service.
- (void)startLocating {
    
    // create core location manager if we haven't already.
    if (!coreLocationManager) coreLocationManager = [[CLLocationManager alloc] init];
    
    // set our desired accuracy.
    coreLocationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    coreLocationManager.distanceFilter  = 1000; // only notify when change is 1000 meters or more
    coreLocationManager.delegate        = self;
    
    // only start updating location if we're able to.
    if ([CLLocationManager locationServicesEnabled]) {
        [coreLocationManager startUpdatingLocation];
        NSLog(@"enabled!");
    }
    
    NSLog(@"basically started");
    
    // after 3 seconds, we hopefully have enough accuracy.
    [self performSelector:@selector(stopLocating) withObject:nil afterDelay:3];
    
}

- (void)stopLocating {
    NSLog(@"assuming accuracy is good enough");
    
    // fetch the current conditions if location was found
    // FIXME: what is latitude is 0? that's still valid...
    if (currentLocation.coordinate.latitude) [currentLocation fetchCurrentConditions];
    
}

#pragma mark - CLLocationManagerDelegate

// got a location update. set our current location object's coordinates.
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *recentLocation = [locations lastObject];
    NSLog(@"updating location: %f,%f", recentLocation.coordinate.latitude, recentLocation.coordinate.longitude);
    
    // set our current location.
    currentLocation.coordinate   = recentLocation.coordinate;
    currentLocation.locationAsOf = [NSDate date];
    
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager {
    NSLog(@"resumed location updates");
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"location error: %@", error);
}

@end
