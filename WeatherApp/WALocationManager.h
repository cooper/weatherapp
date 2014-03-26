//
//  WALocationManager.h
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/28/13.
//  Copyright (c) 2013-14 Mitchell Cooper. All rights reserved.
//

@interface WALocationManager : NSObject <UIPageViewControllerDataSource>

@property NSMutableArray *locations;                    // list of location objects
@property WALocation *currentLocation;                  // the current location object
@property NSOperationQueue *queue;                      // queue for JSON parsing

- (WALocation *)createLocation;                         // creates a location and adds it to manager
- (WALocation *)createLocationFromDictionary:(NSDictionary *)dictionary; // create from user defaults
- (void)destroyLocation:(WALocation *)location;         // destroys a location by removing from manager
- (void)loadLocations:(NSArray *)locationsArray;        // creates locations from user defaults array
- (NSArray *)locationsArrayForSaving;                   // locations array for user defaults
- (void)fetchLocations;                                 // fetches conditions of all locations but current
- (void)focusLocationAtIndex:(NSUInteger)index;

@end
