//
//  WALocationManager.h
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/28/13.
//  Copyright (c) 2013 Really Good. All rights reserved.
//

@interface WALocationManager : NSObject <UIPageViewControllerDataSource>

@property NSMutableArray *locations;
@property NSInteger index;
@property WALocation *currentLocation;

- (WALocation *)createLocation;                         // creates a location and adds it to manager
- (WALocation *)createLocationFromDictionary:(NSDictionary *)dictionary;
- (void)destroyLocation:(WALocation *)location;         // destroys a location by removing from manager
- (void)loadLocations:(NSArray *)locationsArray;        // creates locations from user defaults array
- (NSArray *)locationsArrayForSaving;                   // locations array for user defaults
- (void)fetchLocations;                                 // fetches conditions of all locations but current
- (void)focusLocationAtIndex:(NSUInteger)index;

@end
