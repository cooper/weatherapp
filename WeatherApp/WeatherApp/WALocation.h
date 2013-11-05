//
//  WALocation.h
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/28/13.
//  Copyright (c) 2013 Really Good. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WAAppDelegate.h"

typedef void(^WALocationCallback)(NSURLResponse *res, NSDictionary *data, NSError *err);

@class WAWeatherVC, WALocationManager;

@interface WALocation : NSObject <NSURLConnectionDataDelegate>

#pragma mark - General properties

@property (weak) WALocationManager *manager;    // the manager
@property WAWeatherVC *viewController;          // the associated view controller
@property BOOL isCurrentLocation;               // true if this is current location object
@property (readonly) NSUInteger index;          // index in the manager

#pragma mark - Location information

@property (nonatomic) NSString *countryCode;            // common country code
@property (nonatomic) NSString *country3166;            // ISO 3166 country code
@property (nonatomic) NSString *region;                 // state, province, country, etc.
@property (nonatomic) NSString *regionCode;             // state, province, country, etc. code
@property (nonatomic) NSString *city;                   // full name of city
@property (nonatomic, readonly) NSString *fullName;     // city and region separated by comma
@property NSString *l;                                  // wunderground location query identifier

#pragma mark - Global position

@property NSDate *locationAsOf;                 // date of last location check
@property (nonatomic) float latitude;           // set automatically when coordinate set
@property (nonatomic) float longitude;          // set automatically when coordinate set

#pragma mark - Weather conditions

@property NSDate *conditionsAsOf;               // date of last condition check
@property UIImage *conditionsImage;             // icon image of conditions
@property (nonatomic) float degreesC;           // current temp (C)
@property (nonatomic) float degreesF;           // current temp (F)
@property (nonatomic) NSString *conditions;     // recent conditions; i.e. "Cloudy"

#pragma mark - Fetching data

- (void)fetchCurrentConditions;
- (void)fetchCurrentConditionsThen:(WACallback)then;
- (void)fetchThreeDayForecast;

#pragma mark - User defaults

- (NSDictionary *)userDefaultsDict;

@end
