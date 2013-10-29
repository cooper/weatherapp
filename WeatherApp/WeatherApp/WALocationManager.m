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
    [self.locations addObject:location];
    
    // create a weather view controller for the location.
    WAWeatherVC *weatherVC  = [[WAWeatherVC alloc] initWithNibName:@"WAWeatherVC" bundle:nil];
    location.viewController = weatherVC;
    weatherVC.location      = location;
    
    NSLog(@"Created location %d: %@", [self.locations indexOfObject:location], location);
    return location;
}

// delete our reference to this location so it can be disposed of.
- (void)destroyLocation:(WALocation *)location {
    [self.locations removeObject:location];
}

#pragma mark - UIPageViewControllerSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    
    // find index of this location.
    WAWeatherVC *vc     = (WAWeatherVC *)viewController;
    NSInteger index     = [self.locations indexOfObject:vc.location];
    
    // we cannot have a negative index.
    if (index - 1 < 0) return nil;
    
    // found it.
    WALocation *before  = self.locations[index - 1];
    return before.viewController;
    
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    
    // find the index of this location.
    WAWeatherVC *vc     = (WAWeatherVC *)viewController;
    NSInteger index     = [self.locations indexOfObject:vc.location];
    
    // after index exceeds our number of locations.
    if (index + 1 >= [self.locations count]) return nil;
    
    // found it.
    WALocation *after   = self.locations[index + 1];
    return after.viewController;
    
}

@end
