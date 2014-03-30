//
//  WALocationManager.m
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/28/13.
//  Copyright (c) 2013-14 Mitchell Cooper. All rights reserved.
//

#import "WALocationManager.h"
#import "WALocation.h"
#import "WAWeatherVC.h"
#import "WAPageViewController.h"

@implementation WALocationManager

- (instancetype)init {
    self = [super init];
    if (self) {
        self.locations = [NSMutableArray array];
        self.queue     = [NSOperationQueue new];
    }
    return self;
}

#pragma mark - Creating and destroying locations

// creates a location and adds it to this manager.
- (WALocation *)createLocation {
    
    // create and add to manager.
    WALocation *location = [WALocation new];
    location.loading     = YES;
    location.manager     = self; // weak
    [self.locations addObject:location];
    
    return location;
}

// create a location from a dictionary of properties.
- (WALocation *)createLocationFromDictionary:(NSDictionary *)dictionary {
    WALocation *location = [self createLocation];
    for (NSString *key in dictionary) {
        if (![location respondsToSelector:NSSelectorFromString(key)]) continue;
        [location setValue:dictionary[key] forKey:key];
    }
    if (location.isCurrentLocation) self.currentLocation = location;
    return location;
}

// delete our reference to this location so it can be disposed of.
- (void)destroyLocation:(WALocation *)location {
    // these references should be okay since one is weak,
    // but we may as well destroy them since we know this
    // location will be destroyed soon.
    
    location.overviewVC.location = nil;
    location.overviewVC = nil;
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
        [location commitRequest];
    }
}

#pragma mark - User defaults

// load an array of locations from the database.
- (void)loadLocations:(NSArray *)locationsArray {
    if (!locationsArray) return;
    for (NSDictionary *l in locationsArray)
        [self createLocationFromDictionary:l];
}

// create an array of locations for saving in the database.
- (NSArray *)locationsArrayForSaving {
    NSMutableArray *locs = [NSMutableArray array];
    for (WALocation *location in self.locations)
        [locs addObject:location.userDefaultsDict];
    return locs;
}

#pragma mark - Page view controller source

// fetch the view controller before another.
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    
    // find index of this location.
    NSInteger index;
    if ([viewController isKindOfClass:[WAWeatherVC class]]) {
        WAWeatherVC *vc = (WAWeatherVC *)viewController;
        index           = [self.locations indexOfObject:vc.location];
    }
    else index = -1;
    
    // we cannot have a negative index.
    if (index - 1 < 0) return nil;
    
    // found it.
    WALocation *before  = self.locations[index - 1];
    return before.overviewVC;
    
}

// fetch the view controller after another.
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    
    // find the index of this location.
    NSInteger index;
    if ([viewController isKindOfClass:[WAWeatherVC class]]) {
        WAWeatherVC *vc = (WAWeatherVC *)viewController;
        index           = [self.locations indexOfObject:vc.location];
    }
    else index = -1;
    
    // after index exceeds our number of locations.
    if (index + 1 >= [self.locations count]) return nil;
    
    // found it.
    WALocation *after   = self.locations[index + 1];
    return after.overviewVC;
    
}

// focus the location at the given index.
- (void)focusLocationAtIndex:(NSUInteger)index {
    if (index >= [self.locations count]) return;
    WALocation *location = self.locations[index];
    [appDelegate.pageViewController setViewController:location.overviewVC];
}

@end
