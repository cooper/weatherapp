//
//  WALocation.h
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/28/13.
//  Copyright (c) 2013-14 Mitchell Cooper. All rights reserved.
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
@property BOOL dummy;                                   // dummy for reordering.

#pragma mark - Location information

@property NSString *countryCode;                        // common country code
@property NSString *country3166;                        // ISO 3166 country code
@property NSString *region;                             // state, province, country, etc.
@property NSString *regionCode;                         // state, province, country, etc. code
@property NSString *city;                               // full name of city
@property (readonly) NSString *fullName;                // city and region separated by comma
@property NSString *l;                                  // wunderground location query identifier
@property NSString *longName;                           // location name as looked up

+ (id)newDummy;

#pragma mark - Global position

@property NSDate *locationAsOf;                         // date of last location check
@property float latitude;                               // set automatically when coordinate set
@property float longitude;                              // set automatically when coordinate set

#pragma mark - Weather conditions

@property NSString *conditions;                         // recent conditions; i.e. "Cloudy"
@property NSDictionary *response;                       // recent conditions response

// times.
@property NSDate *conditionsAsOf;                       // date of last condition check
@property NSDate *observationsAsOf;                     // observation unix time
@property NSString *observationTimeString;              // observation time string

// icons.
@property UIImage  *conditionsImage;                    // icon image of conditions
@property NSString *conditionsImageName;                // name of image; i.e. "partlycloudy"
@property BOOL nightTime;                               // is it night time?

// temperatures.
@property float degreesC;                               // current temp (C)
@property float degreesF;                               // current temp (F)
@property float highC;                                  // high temp (C)
@property float highF;                                  // high temp (F)
@property float feelsLikeC;                             // feels like (C)
@property float feelsLikeF;                             // feels like (F)
@property float dewPointC;                              // dew point (C)
@property float dewPointF;                              // dew point (F)
@property float heatIndexC;                             // heat index (C)
@property float heatIndexF;                             // heat index (F)
@property float windchillC;                             // windchill (C)
@property float windchillF;                             // windchill (F)

// localized temperatures.
@property (readonly) NSString *temperature;             // localized temperature string
@property (readonly) NSString *tempUnit;                // localized temperature unit
@property (readonly) NSString *highTemp;                // localized high temperature string
@property (readonly) NSString *feelsLike;               // localized feels like string
@property (readonly) NSString *dewPoint;                // localized dew point string
@property (readonly) NSString *heatIndex;               // localized heat index string
@property (readonly) NSString *windchill;               // localized windchill string

// forecasts.
@property NSArray *forecast;                            // recent forecast response
@property NSMutableArray *fakeLocations;                // location objects for forecast

#pragma mark - Backgrounds

@property UIImage *background;
@property UIImage *cellBackground;
@property NSString *currentBackgroundName;
@property NSString *currentBackgroundIcon;
@property NSString *currentBackgroundConditions;
@property BOOL currentBackgroundTimeOfDay;

- (void)updateBackgroundBoth:(BOOL)both;

#pragma mark - Fetching data

- (void)fetchCurrentConditions;
- (void)fetchCurrentConditionsThen:(WACallback)then;
- (void)fetchForecast;
- (void)fetchIcon;

#pragma mark - User defaults

- (NSDictionary *)userDefaultsDict;

@end
