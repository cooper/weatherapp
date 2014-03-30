//
//  WALocation.h
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/28/13.
//  Copyright (c) 2013-14 Mitchell Cooper. All rights reserved.
//

@interface WALocation : NSObject <NSURLConnectionDataDelegate> {

    // features for requests.
    BOOL willFetchConditions;
    BOOL willFetchDaily10Day;
    BOOL willFetchHourly;
    BOOL willFetchHourly10Day;
    
    // backgrounds.
    NSString        *currentBackgroundName;             // name of the current background
    NSString        *currentBackgroundIcon;             // icon name from current background
    NSString        *currentBackgroundConditions;       // conditions from current background
    BOOL            currentBackgroundTimeOfDay;         // time of day from current background

    // daily forecast.
    NSMutableArray  *fakeLocations;                     // fake location objects for forecast cells

    // hourly forecast.
    NSUInteger      lastDay;                            // the day in the month of the last hour checked
    NSUInteger      currentDayIndex;                    // the index of the current day, starting at 0

}

#pragma mark - General

@property (weak)     WALocationManager *manager;        // our location manager
@property (readonly) NSUInteger index;                  // index in the location manager
@property BOOL isCurrentLocation;                       // true if this is current location object
@property BOOL loading;                                 // some sort of location info is loading now
@property BOOL initialLoadingComplete;                  // initial conditions check after launch
@property BOOL dummy;                                   // this is a dummy for reordering in list

+ (id)newDummy;                                         // creates a dummy for reordering in list
- (NSDictionary *)userDefaultsDict;                     // creates a dictionary to be stored in database

#pragma mark - View controllers

@property WAWeatherVC          *overviewVC;             // overview view controller
@property WAConditionDetailTVC *detailVC;               // more details view controller
@property WADailyForecastTVC   *dailyVC;                // daily forecast view controller
@property WAHourlyForecastTVC  *hourlyVC;               // hourly forecast view controller

#pragma mark - Location information

@property NSString *countryCode;                        // common country code
@property NSString *country3166;                        // ISO 3166 country code
@property NSString *region;                             // state, province, country, etc.
@property NSString *regionCode;                         // state, province, country, etc. code
@property NSString *city;                               // full name of city
@property NSString *l;                                  // wunderground location query identifier
@property NSString *longName;                           // full location name as looked up
@property (readonly) NSString *fullName;                // city and region separated by comma

#pragma mark - Global position

@property NSDate *locationAsOf;                         // date of last location check
@property float  latitude;                              // set automatically when coordinate set
@property float  longitude;                             // set automatically when coordinate set

#pragma mark - Weather conditions

@property NSString     *conditions;                     // recent conditions; i.e. "Cloudy"
@property NSDictionary *response;                       // recent conditions response

#pragma mark - Time

@property NSDate     *conditionsAsOf;                   // date of last condition check
@property NSDate     *observationsAsOf;                 // observation unix time
@property NSString   *observationTimeString;            // observation time string
@property NSTimeZone *timeZone;                         // time zone in this location

#pragma mark - Icons

@property UIImage  *conditionsImage;                    // icon image of conditions
@property NSString *conditionsImageName;                // name of image; i.e. "partlycloudy"
@property BOOL     nightTime;                           // is it night time?

#pragma mark - Temperatures

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

// methods for extra decimal places.
- (NSString *)temperature:(UInt8)decimalPlaces;         // localized with desired decimals
- (NSString *)feelsLike:(UInt8)decimalPlaces;           // localized with desired decimals
- (NSString *)highTemp:(UInt8)decimalPlaces;            // localized with desired decimals
- (NSString *)dewPoint:(UInt8)decimalPlaces;            // localized with desired decimals
- (NSString *)heatIndex:(UInt8)decimalPlaces;           // localized with desired decimals
- (NSString *)windchill:(UInt8)decimalPlaces;           // localized with desired decimals

#pragma mark - Forecasts and details

// daily.
@property NSArray        *forecastResponse;             // recent forecast response
@property NSMutableArray *dailyForecast;                // generated daily forecast info
@property NSDate         *dailyForecastAsOf;            // time last daily forecast fetched

// hourly.
@property NSArray        *hourlyForecastResponse;       // recent hourly forecast response
@property NSMutableArray *hourlyForecast;               // generated hourly forecast info
@property NSDate         *hourlyForecastAsOf;           // time last hourly forecast fetched

// details.
@property NSMutableArray *extensiveDetails;             // generated details for cells

- (void)updateDailyForecast;                            // recompile daily forecast info
- (void)updateHourlyForecast;                           // recompile hourly forecast info
- (void)updateExtensiveDetails;                         // recompile extensive details

#pragma mark - Backgrounds

@property UIImage *background;                          // the full-size background image
@property UIImage *cellBackground;                      // the 100x320pt cell background

- (void)updateBackgroundBoth:(BOOL)both;                // update backgrounds (cell or both)

#pragma mark - Fetching data

- (void)fetchCurrentConditions;                         // fetch the current conditions
- (void)fetchForecast;                                  // fetch daily (10 day) forecast
- (void)fetchHourlyForecast:(BOOL)tenDay;               // fetch hourly forecast (3 or 10 days)
- (void)commitRequest;                                  // make the HTTP request
- (void)commitRequestThen:(WALocationCallback)callback; // make the HTTP request with callback
- (void)fetchIcon;                                      // resolve icon and fetch if needed

@end
