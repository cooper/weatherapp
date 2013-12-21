//
//  WALocation.h
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/28/13.
//  Copyright (c) 2013 Really Good. All rights reserved.
//


typedef void(^WALocationCallback)(NSURLResponse *res, NSDictionary *data, NSError *err);

@interface WALocation : NSObject <NSURLConnectionDataDelegate>

#pragma mark - General properties

@property (weak) WALocationManager *manager;            // the manager
@property WAWeatherVC *viewController;                  // the associated view controller
@property BOOL isCurrentLocation;                       // true if this is current location object
@property (readonly) NSUInteger index;                  // index in the manager
@property BOOL loading;                                 // location info is loading now
@property BOOL initialLoadingComplete;                  // initial conditions check after launch

#pragma mark - Location information

@property NSString *countryCode;                        // common country code
@property NSString *country3166;                        // ISO 3166 country code
@property NSString *region;                             // state, province, country, etc.
@property NSString *regionCode;                         // state, province, country, etc. code
@property NSString *city;                               // full name of city
@property (readonly) NSString *fullName;                // city and region separated by comma
@property NSString *l;                                  // wunderground location query identifier
@property NSString *longName;                           // location name as looked up


#pragma mark - Global position

@property NSDate *locationAsOf;                         // date of last location check
@property float latitude;                               // set automatically when coordinate set
@property float longitude;                              // set automatically when coordinate set

#pragma mark - Weather conditions

@property NSDate *conditionsAsOf;                       // date of last condition check
@property UIImage  *conditionsImage;                    // icon image of conditions
@property NSString *conditionsImageName;                // name of image; i.e. "partlycloudy"
@property float degreesC;                               // current temp (C)
@property float degreesF;                               // current temp (F)
@property (readonly) NSString *temperature;             // localized temperature string
@property (readonly) NSString *tempUnit;                // localized temperature unit
@property NSString *conditions;                         // recent conditions; i.e. "Cloudy"
@property BOOL nightTime;                               // is it night time?

#pragma mark - Fetching data

- (void)fetchCurrentConditions;
- (void)fetchCurrentConditionsThen:(WACallback)then;
- (void)fetchThreeDayForecast;

#pragma mark - User defaults

- (NSDictionary *)userDefaultsDict;

@end
