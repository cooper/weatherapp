//
//  WALocation.h
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/28/13.
//  Copyright (c) 2013 Really Good. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "WAAppDelegate.h"

typedef void(^WALocationCallback)(NSURLResponse *res, NSDictionary *data, NSError *err);

@class WAWeatherVC, WALocationManager;

@interface WALocation : NSObject <NSURLConnectionDataDelegate> {
    CLLocationCoordinate2D _coordinate;         // coordinate property instance variable
    BOOL inGeoLookup;                           // whether a geolookup is being done now
}

@property (weak) WALocationManager *manager;
@property WAWeatherVC *viewController;          // the associated view controller
@property NSUInteger index;

#pragma mark - Location information

@property (nonatomic) NSString *country;                // country name; i.e. South Africa
@property (nonatomic) NSString *countryShort;           // short country name; i.e. ZA (South Africa)
@property (nonatomic) NSString *state;                  // state name; i.e. Indiana
@property (nonatomic) NSString *stateShort;             // short name of state; i.e. IN
@property (nonatomic) NSString *city;                   // city name; i.e. Chalmers
@property (nonatomic, readonly) NSString *fullName;     // full name; i.e. Chalmers, Indiana

#pragma mark - Automatic properties

@property (nonatomic, readonly) NSString *region;       // state or country; i.e. South Africa
@property (nonatomic, readonly) NSString *regionShort;  // short name of region; i.e. ZA (South Africa)

#pragma mark - Safe properties

@property (readonly) NSString *safeCity;            // safe properties are URL-encoded
@property (readonly) NSString *safeRegion;
@property (readonly) NSString *safeRegionShort;
@property (readonly) NSString *lookupRegion;

#pragma mark - Current location

@property BOOL isCurrentLocation;               // true if this is current location object
@property NSDate *locationAsOf;                 // date of last location check
@property CLLocationCoordinate2D coordinate;    // lat/lon coordinates

#pragma mark - Recent weather conditions

@property NSDate *conditionsAsOf;               // date of last condition check
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
