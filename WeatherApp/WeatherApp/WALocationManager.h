//
//  WALocationManager.h
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/28/13.
//  Copyright (c) 2013 Really Good. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WALocation;

@interface WALocationManager : NSObject <UIPageViewControllerDataSource>

@property NSMutableArray *locations;

- (WALocation *)createLocation;                         // creates a location and adds it to manager
- (WALocation *)createLocationFromDictionary:(NSDictionary *)dictionary;
- (void)destroyLocation:(WALocation *)location;         // destroys a location by removing from manager
- (void)loadLocations:(NSDictionary *)locationsDict;    // creates locations from user defaults dictionary
- (void)fetchLocations;                                 // fetches conditions of all locations but current

@end
