//
//  WALocationManager.m
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/28/13.
//  Copyright (c) 2013 Really Good. All rights reserved.
//

#import "WALocationManager.h"
#import "WALocation.h"
#import "WAWeatherVC.h"
#import "WANavigationController.h"
#import "WAAppDelegate.h"

@implementation WALocationManager

- (id)init
{
    self = [super init];
    if (self) {
        self.locations = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Creating and destroying locations

// creates a location and adds it to this manager.
- (WALocation *)createLocation {
    
    // create and add to manager.
    WALocation *location = [[WALocation alloc] init];
    location.manager     = self; // weak
    [self.locations addObject:location];
    
    // create a weather view controller for the location.
    WAWeatherVC *weatherVC  = [[WAWeatherVC alloc] initWithNibName:@"WAWeatherVC" bundle:nil];
    location.viewController = weatherVC;
    weatherVC.location      = location; // weak
    
    NSLog(@"Created location %lu: %@", (unsigned long)[self.locations indexOfObject:location], location);
    return location;
}

// create a location from a dictionary of properties.
- (WALocation *)createLocationFromDictionary:(NSDictionary *)dictionary {
    WALocation *location = [self createLocation];
    for (NSString *key in dictionary) {
        NSLog(@"checking %@", key);
        if (![location respondsToSelector:NSSelectorFromString(key)]) continue;
        NSLog(@"settings %@", key);
        [location setValue:dictionary[key] forKey:key];
    }
    return location;
}

// delete our reference to this location so it can be disposed of.
- (void)destroyLocation:(WALocation *)location {
    // these references should be okay since one is weak,
    // but we may as well destroy them since we know this
    // location will be destroyed soon.
    
    location.viewController.location = nil;
    location.viewController = nil;
    [self.locations removeObject:location];
}

#pragma mark - Fetching weather data

// fetches current conditions of all locations other than the current location.
- (void)fetchLocations {
    for (WALocation *location in self.locations) {
        
        // ignore the current location; it will be fetched
        // later when the location is determined.
        if (location.isCurrentLocation) continue;
        
        [location fetchCurrentConditions];
        
    }
}

#pragma mark - Page view controller source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    
    // find index of this location.
    NSInteger index;
    if ([viewController isKindOfClass:[WAWeatherVC class]]) {
        WAWeatherVC *vc = (WAWeatherVC *)viewController;
        index           = [self.locations indexOfObject:vc.location];
    }
    else index = -1;
    
    // otherwise we cannot have a negative index.
    if (index - 1 < 0) return nil;
    
    // found it.
    WALocation *before  = self.locations[index - 1];
    [DEFAULTS setInteger:(index - 1) forKey:@"focused_location_index"];
    return before.viewController;
    
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    
    // find the index of this location.
    NSInteger index;
    if ([viewController isKindOfClass:[WAWeatherVC class]]) {
        WAWeatherVC *vc = (WAWeatherVC *)viewController;
        index           = [self.locations indexOfObject:vc.location];
    }
    else index = INFINITY;
    
    // after index exceeds our number of locations.
    if (index + 1 >= [self.locations count]) return nil;
    
    // found it.
    WALocation *after = self.locations[index + 1];
    [DEFAULTS setInteger:(index + 1) forKey:@"focused_location_index"];
    return after.viewController;
    
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    return [self.locations count];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
    return self.index ? self.index : 0;
}

#pragma mark - Page VC management

// bring the location at given index to front of page view.
- (void)focusLocationAtIndex:(NSUInteger)index {

    // ensure this location exists.
    WALocation *location = self.locations[index];
    if (!location) return;
    
    // used for page indicator.
    self.index = index;
    
    // set the view controllers to this one only.
    //[APP_DELEGATE.pageVC setViewControllers:@[location.viewController] direction:UIPageViewControllerNavigationDirectionReverse animated:NO completion:nil];
    
    [DEFAULTS setInteger:index forKey:@"focused_location_index"];
    
}

#pragma mark - User defaults

- (void)loadLocations:(NSArray *)locationsArray {
    if (!locationsArray) return;
    //unsigned int i = 0;
    for (NSDictionary *l in locationsArray) [self createLocationFromDictionary:l];
}

- (NSArray *)locationsArrayForSaving {
    NSMutableArray *locs = [NSMutableArray array];
    for (WALocation *location in self.locations) [locs addObject:location.userDefaultsDict];
    return locs;
}

@end
