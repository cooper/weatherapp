//
//  WALocation.h
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/28/13.
//  Copyright (c) 2013-14 Mitchell Cooper. All rights reserved.
//


typedef void(^WALocationCallback)(NSURLResponse *res, NSDictionary *data, NSError *err);

@interface WALocation : NSObject <NSURLConnectionDataDelegate> {

    // hourly forecast.
    NSMutableArray  *hourly;                // array containing hourly forecast data
    NSUInteger      lastDay;                // the day in the month of the last hour checked
    NSUInteger      currentDayIndex;        // the index of the current day, starting at 0
    NSMutableArray  *daysAdded;             // track which days added to say "next" weekday
    
}

#pragma mark - General properties

@property (weak) WALocationManager *manager;            // the manager

@property WAWeatherVC *overviewVC;                      // overview view controller
@property WAConditionDetailTVC *detailVC;               // more details view controller
@property WADailyForecastTVC *dailyVC;                  // daily forecast view controller
@property WAHourlyForecastTVC *hourlyVC;                // hourly forecast view controller

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
@property NSTimeZone *timeZone;                         // time zone in this location

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

// methods for extra decimal places.
- (NSString *)temperature:(UInt8)decimalPlaces;         // localized with desired decimals
- (NSString *)feelsLike:(UInt8)decimalPlaces;           // localized with desired decimals
- (NSString *)highTemp:(UInt8)decimalPlaces;            // localized with desired decimals
- (NSString *)dewPoint:(UInt8)decimalPlaces;            // localized with desired decimals
- (NSString *)heatIndex:(UInt8)decimalPlaces;           // localized with desired decimals
- (NSString *)windchill:(UInt8)decimalPlaces;           // localized with desired decimals

// forecasts and details.
@property NSArray *forecastResponse;                    // recent forecast response
@property NSMutableArray *dailyForecast;                // generated daily forecast info
@property NSMutableArray *fakeLocations;                // location objects for forecast
@property NSArray *hourlyForecastResponse;              // recent hourly forecast response
@property NSMutableArray *hourlyForecast;               // generated hourly forecast info
@property NSDate *hourlyForecastAsOf;
@property NSDate *dailyForecastAsOf;
@property NSMutableArray *extensiveDetails;             // generated details

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
- (void)fetchHourlyForecast:(BOOL)tenDay;
- (void)fetchIcon;

#pragma mark - Forecasts and details

- (void)updateDailyForecast;
- (void)updateHourlyForecast;
- (void)updateExtensiveDetails;

#pragma mark - User defaults

- (NSDictionary *)userDefaultsDict;

@end
