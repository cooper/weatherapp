//
//  WALocation.m
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/28/13.
//  Copyright (c) 2013-14 Mitchell Cooper. All rights reserved.
//

#import "WALocation.h"
#import "WALocationManager.h"

#import "WANavigationController.h"
#import "WALocationListTVC.h"
#import "WAPageViewController.h"

#import "WAWeatherVC.h"
#import "WAConditionDetailTVC.h"
#import "WAHourlyForecastTVC.h"
#import "WADailyForecastTVC.h"

#import "UIImage+Preload.h"

@implementation WALocation

- (instancetype)init {
    self = [super init];
    if (self) {
        self.highC      =
        self.highF      =
        self.degreesC   =
        self.degreesF   =
        self.heatIndexC =
        self.heatIndexF =
        self.windchillC =
        self.windchillF =
        self.feelsLikeC =
        self.feelsLikeF = TEMP_NONE;
    }
    return self;
}

// create a new dummy location.
+ (id)newDummy {
    WALocation *location = [self new];
    location.dummy = YES;
    return location;
}

#pragma mark - Fetching data

// add conditions to queue.
- (void)fetchCurrentConditions {
    willFetchConditions = YES;
}

// add daily forecast to queue.
- (void)fetchForecast {
    willFetchDaily10Day = YES;
}

// add hourly forecast to queue.
- (void)fetchHourlyForecast:(BOOL)tenDay {
    if (tenDay) willFetchHourly10Day = YES;
    else        willFetchHourly      = YES;
}

// make an HTTP request.
- (void)commitRequest {
    [self commitRequestThen:nil];
}

// make an HTTP request with a callback.
- (void)commitRequestThen:(WALocationCallback)callback {
    NSMutableArray *features = [NSMutableArray arrayWithCapacity:4];
    if (willFetchConditions)  [features addObject:@"conditions"];
    if (willFetchDaily10Day)  [features addObject:@"forecast10day"];
    if (willFetchHourly10Day) [features addObject:@"hourly10day"];
    if (willFetchHourly)      [features addObject:@"hourly"];
    
    NSString *page = [features componentsJoinedByString:@"/"];
    [self fetch:page then:callback];
    
    // reset these values.
    willFetchConditions  =
    willFetchDaily10Day  =
    willFetchHourly10Day =
    willFetchHourly      = NO;
    
}

// determine icon and download if necessary.
- (void)fetchIcon {
    NSDictionary *ob = self.response;
    
    // if an icon is included in the response, use it.
    // if the weather API icon contains "/nt", use a nighttime icon.
    if (ob[@"icon"]) {
        NSString *icon = ob[@"icon"];
        
        // alternate names for icons.
        if ([icon isEqualToString:@"hazy"])         icon = @"fog";
        if ([icon isEqualToString:@"partlysunny"])  icon = @"partlycloudy";
        
        // we don't care about chances.
        icon = [icon stringByReplacingOccurrencesOfString:@"chance" withString:@""];
        
        // determine the image name (night/day)
        self.nightTime     = [ob[@"icon_url"] rangeOfString:@"/nt"].location != NSNotFound;
        NSString *timeName = FMT(@"%@%@", self.nightTime ? @"nt_" : @"", icon);
        
        // attempt to use the day/night version.
        self.conditionsImage     = [UIImage imageNamed:FMT(@"icons/50/%@", timeName)];
        self.conditionsImageName = timeName;

        // if it's nighttime and the image does not exist, fall back to a daytime image.
        if (self.nightTime && !self.conditionsImage) {
            self.conditionsImageName = icon;
            self.conditionsImage     = [UIImage imageNamed:FMT(@"icons/50/%@", icon)];
        }
        
    }

    // if we don't have an icon by now, download wunderground's.
    if (ob[@"icon_url"] && !self.conditionsImage) {
        NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:ob[@"icon_url"]]];
        [self beginLoading];
        [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            [self endLoading];
            if (!data) return;
            self.conditionsImage = [UIImage imageWithData:data];
        }];
    }
    
}

// send a request to the API. runs asynchronously, decodes JSON,
// and then executes the callback with an dictionary argument in main queue.
- (void)fetch:(NSString *)page then:(WALocationCallback)callback {
    [self beginLoading];
    NSString *query = [self bestLookupMethod:page];
    NSLog(@"Request for %@: %@", OR(self.city, @"unknown location"), page);
    
    // create a request for the weather underground API.
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:FMT(@"http://api.wunderground.com/api/" WU_API_KEY @"/%@", query)]];
    
    // send a request asyncrhonously.
    [NSURLConnection sendAsynchronousRequest:request queue:self.manager.queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
    
        // an error occurred.
        if (connectionError || !data) {
            [self handleError:connectionError.localizedDescription];
            return;
        }
        
        NSError *error;
        id jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        NSLog(@"%@", jsonData);

        // an error occurred.
        if (error) {
            [self handleError:@"Error decoding JSON response: %@"];
            return;
        }
        
        // ensure that the data is a dictionary (JSON object).
        if (![jsonData isKindOfClass:[NSDictionary class]]) {
            [self handleError:@"JSON response is not of object type."];
            return;
        }
        
        // everything looks well; go ahead and fire the callback in main queue.
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
            // create the view controller if we haven't already.
            if (!self.initialLoadingComplete) {
                self.overviewVC = [[WAWeatherVC alloc] initWithLocation:self];
                self.initialLoadingComplete = YES;
            }
        
            // pass on to the appropriate handler.
            NSDictionary *features = [[jsonData objectForKey:@"response"] objectForKey:@"features"];
            [self handleJSON:jsonData features:features];

            [self endLoading];
        
            // callback if necessary.
            if (callback) callback(response, jsonData);
            
            // update the database.
            [appDelegate saveLocationsInDatabase];
        
        }];
    
    }];
}

// determine the URL based on available information.
- (NSString *)bestLookupMethod:(NSString *)type {

    // determine how we will look up this location.
    NSString *q;
    
    // use our coordinates.
    if (self.isCurrentLocation) {
        NSLog(@"Looking up %@ with %f,%f", type, self.latitude, self.longitude);
        q = FMT(@"%@/q/%f,%f.json", type, self.latitude, self.longitude);
    }
    
    // use wunderground ID.
    else if ([self.l length]) {
        NSLog(@"Looking %@ up with %@", type, self.l);
        q = FMT(@"%@/%@.json", type, self.l);
    }
    
    // use the preferred region and city name.
    else {
        NSLog(@"Looking up %@ with %@", type, self.fullName);
        q = FMT(@"%@/q/%@/%@.json", type, URL_ESC(self.region), URL_ESC(self.city));
    }

    return q;
}

#pragma mark - Handling data

- (void)handleJSON:(NSDictionary *)data features:(NSDictionary *)features {

    // force the view to load if it hasn't already.
    [self.overviewVC view];

    // current conditions.
    if (features[@"conditions"])
        [self handleCurrentConditions:data[@"current_observation"]];
    
    // hourly.
    if (features[@"hourly"] || features[@"hourly10day"])
        [self handleHourlyForecast:data[@"hourly_forecast"]];
    
    // daily.
    if (features[@"forecast"] || features[@"forecast10day"])
        [self handleForecast:data[@"forecast"][@"simpleforecast"][@"forecastday"]];
    
}

// fetches and updates the current weather conditions of the location.
- (void)handleCurrentConditions:(NSDictionary *)ob {
    NSDictionary *loc = ob[@"display_location"];
    NSLog(@"Got conditions for %@", loc[@"city"]);
    
    // note: the setters ignore any lengthless value.
    // the setters call the interface methods to make changes.
    
    // fallback to ISO 3166 country code if city == state.
    // we'll make a special exception for PRC through --
    // this is because wunderground says major cities of China are states.
    // I have no way to determine the actual name of the country in this scenario.
    BOOL same = [loc[@"state_name"] isEqualToString:loc[@"city"]];
    NSString *possibleCountryName = [self.country3166 isEqualToString:@"CN"] ? @"China" : self.country3166;
    
    // set our city/region information.
    self.city         = loc[@"city"];
    self.countryCode  = loc[@"country"];
    self.country3166  = loc[@"country_iso3166"];
    self.region       = same ? possibleCountryName : loc[@"state_name"];
    
    // time zone.
    self.timeZone = [NSTimeZone timeZoneWithName:ob[@"local_tz_long"]];
    if (!self.timeZone)
        self.timeZone = [NSTimeZone timeZoneWithAbbreviation:ob[@"local_tz_short"]];
    if (!self.timeZone)
        self.timeZone = [NSTimeZone localTimeZone];
    
    // don't use wunderground's coordinates if this is the current location,
    // because those reported by location services are far more accurate.
    if (!self.isCurrentLocation) {
        self.latitude     = [loc[@"latitude"]  floatValue];
        self.longitude    = [loc[@"longitude"] floatValue];
    }
    
    // reset temperatures.
    self.degreesC   = self.degreesF   =
    self.dewPointC  = self.dewPointF  =
    self.feelsLikeC = self.feelsLikeF =
    self.heatIndexC = self.heatIndexF =
    self.windchillC = self.windchillF =
    self.highC      = self.highF      = TEMP_NONE;
    
    // temperatures.
    // no longer round temperatures to the nearest whole degree here.
    
    self.degreesC   = temp_safe(ob[@"temp_c"]);
    self.degreesF   = temp_safe(ob[@"temp_f"]);
    self.feelsLikeC = temp_safe(ob[@"feelslike_c"]);
    self.feelsLikeF = temp_safe(ob[@"feelslike_f"]);
    
    // dew point.
    if (temp_safe(ob[@"dewpoint_c"]) != TEMP_NONE) {
        self.dewPointC  = temp_safe(ob[@"dewpoint_c"]);
        self.dewPointF  = temp_safe(ob[@"dewpoint_f"]);
    }
    
    // heat index.
    if (temp_safe(ob[@"heat_index_c"]) != TEMP_NONE) {
        self.heatIndexC = temp_safe(ob[@"heat_index_c"]);
        self.heatIndexF = temp_safe(ob[@"heat_index_f"]);
    }
    
    // windchill.
    if (temp_safe(ob[@"windchill_c"]) != TEMP_NONE) {
        self.windchillC = temp_safe(ob[@"windchill_c"]);
        self.windchillF = temp_safe(ob[@"windchill_f"]);
    }
    
    // conditions.
    self.response   = ob;
    self.conditions = ob[@"weather"];
    
    // icon.
    [self fetchIcon];
    
    // update as of time, and finish loading process.
    self.conditionsAsOf   = [NSDate date];
    self.observationsAsOf = [NSDate dateWithTimeIntervalSince1970:[ob[@"observation_epoch"] doubleValue]];
    self.observationTimeString = [ob[@"observation_time"] stringByReplacingOccurrencesOfString:@"Last Updated on " withString:@""];
    
}

// ten-day forecast.
- (void)handleForecast:(NSArray *)forecast {
NSLog(@"handle daily: %@", forecast);
    self.forecastResponse = forecast;
    [self updateDailyForecast];
    self.dailyForecastAsOf = [NSDate date];
}

// hourly forecast.
- (void)handleHourlyForecast:(NSArray *)forecast {
    NSLog(@"handle hourly %@", forecast);
    self.hourlyForecastResponse = forecast;
    [self updateHourlyForecast];
    self.hourlyForecastAsOf = [NSDate date];
}

#pragma mark - Automatic properties

- (NSString *)fullName {
    if (!self.city || !self.region) return nil;
    return FMT(@"%@, %@", self.city, self.region);
}

- (NSUInteger)index {
    return [self.manager.locations indexOfObject:self];
}

- (NSString *)tempUnit {
    if (SETTING_IS(kTemperatureScaleSetting, kTemperatureScaleKelvin))
        return @"K";
    else return @"º";
}

/*  since this is a ton of repetition but the property names are variable,
    I decided to use a macro to define these methods and property getters.
*/

#define tempFunction(NAME, CPROP, FPROP)                                        \
    - (NSString *)NAME {                                                        \
        return [self NAME:0];                                                   \
    }                                                                           \
    - (NSString *)NAME:(UInt8)decimalPlaces {                                   \
        float t;                                                                \
        if (SETTING_IS(kTemperatureScaleSetting, kTemperatureScaleFahrenheit))  \
            t = self.FPROP;                                                     \
        else if (SETTING_IS(kTemperatureScaleSetting, kTemperatureScaleKelvin)) \
            t = self.CPROP + 273.15;                                            \
        else                                                                    \
            t = self.CPROP;                                                     \
        NSString *result = FMT(FMT(@"%%.%df", decimalPlaces), t);               \
        NSRange range    = NSMakeRange([result length] - 2, 2);                 \
        if ([[result substringWithRange:range] isEqualToString:@".0"])          \
            return FMT(@"%.f", t);                                              \
        return result;                                                          \
    }

tempFunction(temperature, degreesC,   degreesF)
tempFunction(windchill,   windchillC, windchillF)
tempFunction(heatIndex,   heatIndexC, heatIndexF)
tempFunction(dewPoint,    dewPointC,  dewPointF)
tempFunction(highTemp,    highC,      highF)
tempFunction(feelsLike,   feelsLikeC, feelsLikeF)

#pragma mark - User defaults

// create a dictionary for storage in the user defaults database.
- (NSDictionary *)userDefaultsDict {
    if (self.dummy) return @{};
    NSArray * const keys = @[
        @"city",                @"longName", @"l",
        @"countryCode",         @"country3166",
        @"regionCode",          @"region",
        @"isCurrentLocation",   @"locationAsOf",
        @"latitude",            @"longitude",
        @"conditions",          @"conditionsAsOf",
        @"conditionsImageName", @"nightTime",
        @"degreesC",            @"degreesF",
        @"feelsLikeC",          @"feelsLikeF",
        @"heatIndexC",          @"heatIndexF"
    ];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    for (NSString *key in keys)
        if ([self valueForKey:key]) dict[key] = [self valueForKey:key];
    
    return dict;
}

#pragma mark - Loading

// indicates begin loading.
- (void)beginLoading {
    self.loading = YES;
    
    // start status bar indicator.
    [appDelegate beginActivity];
    
    // if pageVC exists, update its navigation bar.
    // (to add indicator in place of refresh button)
    if (appDelegate.pageViewController)
        [appDelegate.pageViewController updateNavigationBar];
    
}

// indicates finish loading.
- (void)endLoading {
    self.loading = NO;
    
    // stop the status bar indicator.
    [appDelegate endActivity];
    
    // update the weather view controller's info.
    [self updateBackground];
    
    if (self.overviewVC) [self.overviewVC update];
    if (self.detailVC)   [self.detailVC   update];
    if (self.hourlyVC)   [self.hourlyVC   update];
    if (self.dailyVC)    [self.dailyVC    update];
    
    // if the location list TVC exists, update the cell for this location.
    WALocationListTVC *locationList = appDelegate.navigationController.locationList;
    if (locationList) [locationList updateLocationAtIndex:self.index];
    
    // if the pageVC exists, update the navigation bar.
    // (replace loading indicator with refresh button)
    if (appDelegate.pageViewController)
        [appDelegate.pageViewController updateNavigationBar];
    
}


// handle an error.
- (void)handleError:(NSString *)errstr {
    NSLog(@"Error for %@: %@", OR(self.city, @"unknown location"), errstr);
    [appDelegate displayAlert:FMT(@"%@ error", OR(self.city, @"Location")) message:errstr];
    [self endLoading];
}

#pragma mark - Backgrounds

- (void)updateBackground {
    return [self updateBackgroundBoth:YES];
}

// update the background(s) according to the current conditions.
- (void)updateBackgroundBoth:(BOOL)both {

    // in order by priority. the first match wins.
    
    // matching is case-insensitive. night is preferred if it's night time,
    // but if a night array does not exist, day acts as a fallback.
    
    // the background selector alternates through each array by storing
    // the last-used index in the user defaults database.
    
    // load backgrounds from plist.
    NSString *bgPlist    = [[NSBundle mainBundle] pathForResource:@"backgrounds" ofType:@"plist"];
    NSArray *backgrounds = [NSArray arrayWithContentsOfFile:bgPlist];
    
    // if the icon and conditions haven't changed, don't waste energy analyzing backgrounds.
    unsigned int i = 0; NSDictionary *selection;
    if (![currentBackgroundIcon isEqualToString:self.conditionsImageName] ||
        ![currentBackgroundConditions isEqualToString:self.conditions])
        
    // one or both have changed.
    for (NSDictionary *bg in backgrounds) {
    
        // search for matches in icon.
        BOOL matchesIcon = NO;
        id icons = bg[@"icon"];
        if (icons) {
            if (![icons isKindOfClass:[NSArray class]]) icons = @[icons];
            for (NSString *icon in icons) {
                if ([self.conditionsImageName rangeOfString:icon options:NSCaseInsensitiveSearch].location == NSNotFound)
                    continue;
                matchesIcon = YES;
                break;
            }
        }
        
        // search for matches in conditions.
        BOOL matchesConditions = bg[@"conditions"] && [self.conditions rangeOfString:bg[@"conditions"] options:NSCaseInsensitiveSearch].location != NSNotFound;
        
        // this is a match.
        if (matchesIcon || matchesConditions) {
            
            // if it's night and backgrounds exist for such, prefer them.
            BOOL nightTime = NO;
            if (self.nightTime && bg[@"night"]) nightTime = YES;
            
            // here's our winning list.
            selection = @{
                @"index": @(i),
                @"name":  bg[@"inherit"] ? bg[@"inherit"] : bg[@"name"],
                @"night": @(nightTime)
            };
            break;
            
        }
        
        i++;
    }
    
    // if the background category and time of day are same, nothing needs to be changed.
    NSString *chosenBackground;
    if ([currentBackgroundName isEqualToString:selection[@"name"]] && currentBackgroundTimeOfDay == [selection[@"night"] boolValue])
        NSLog(@"Conditions/icon changed, but category and time of day still same");
    
    // a background group was selected.
    else if (selection) {
        
        unsigned int i      = [selection[@"index"] unsignedIntValue];
        BOOL nightTime      = [selection[@"night"] boolValue];
        NSString *timeOfDay = nightTime ? @"night" : @"day";
        
        
        NSString *storageName = FMT(@"%@-%@", selection[@"name"], timeOfDay);
        NSArray *choices      = backgrounds[i][timeOfDay];
        
        // fetch the background storage.
        NSMutableDictionary *bgStorage = [[DEFAULTS objectForKey:@"backgrounds"] mutableCopy];
        unsigned int useIndex = 0;
        
        // use the one after the last-used.
        if (bgStorage[storageName])
            useIndex = [bgStorage[storageName] unsignedIntValue] + 1;
        
        // we exceeded the array's limits; go back to the first.
        if (useIndex >= [choices count]) useIndex = 0;
        
        // here's the final winner.
        chosenBackground       = choices[useIndex];
        bgStorage[storageName] = @(useIndex);
        [DEFAULTS setObject:bgStorage forKey:@"backgrounds"];
        
    }
    
    // finally apply the background.
    if (!chosenBackground) return;
    
    currentBackgroundName       = selection[@"name"];
    currentBackgroundIcon       = self.conditionsImageName;
    currentBackgroundConditions = self.conditions;
    currentBackgroundTimeOfDay  = [selection[@"night"] boolValue];
    
    // load the full-size background as well.
    if (both) {
        NSString *backgroundFile = [[NSBundle mainBundle] pathForResource:FMT(@"backgrounds/%@", chosenBackground) ofType:@"jpg"];
        self.background = [[UIImage imageWithContentsOfFile:backgroundFile] preloadedImage];
    }

    NSString *cellBackgroundFile = [[NSBundle mainBundle] pathForResource:FMT(@"backgrounds/200/%@", chosenBackground) ofType:@"jpg"];
    self.cellBackground = [[UIImage imageWithContentsOfFile:cellBackgroundFile] preloadedImage];
    
}

#pragma mark - Extensive details

// recompile data for extensive details view.
- (void)updateExtensiveDetails {
    NSMutableArray *final = [NSMutableArray array];
    NSDictionary   *r     = self.response;
    
    // local time formatter.
    NSDateFormatter *fmt = [NSDateFormatter new];
    fmt.dateFormat = @"h:mm a";
    
    // remote time formatter.
    NSDateFormatter *rfmt = [NSDateFormatter new];
    rfmt.timeZone   = self.timeZone;
    rfmt.dateFormat = @"h:mm a";
    
    // initial values of "NA"
    NSString *dewPoint, *heatIndex, *windchill, *pressure, *visibility, *precipT,
        *precipH, *windSpeed, *windDirection, *gustSpeed, *uv;
    dewPoint  = heatIndex = windchill     = pressure  = visibility = precipT = uv =
    precipH   = windSpeed = windDirection = gustSpeed = @"NA";
    
    // dewpoint.
    if (self.dewPointC != TEMP_NONE)
        dewPoint = FMT(@"%@%@", [self dewPoint:1], self.tempUnit);
    
    // heat index.
    if (self.heatIndexC != TEMP_NONE && ![self.temperature isEqualToString:self.heatIndex])
        heatIndex = FMT(@"%@%@", [self heatIndex:1], self.tempUnit);
    
    // windchill.
    if (self.windchillC != TEMP_NONE && ![self.temperature isEqualToString:self.windchill])
        windchill = FMT(@"%@%@", [self windchill:1], self.tempUnit);
    
    // precipitation.
    BOOL isT = [r[@"precip_today_metric"] floatValue] > 0;
    BOOL isH = [r[@"precip_1hr_metric"]   floatValue] > 0;
    
    // in inches.
    if (SETTING_IS(kPrecipitationMeasureSetting, kPrecipitationMeasureInches)) {
        if (isT) precipT = FMT(@"%@ in", r[@"precip_today_in"]);
        if (isH) precipH = FMT(@"%@ in", r[@"precip_1hr_in"]);
    }
    
    // in millimeters.
    else {
        if (isT) precipT = FMT(@"%@ in", r[@"precip_today_metric"]);
        if (isH) precipH = FMT(@"%@ in", r[@"precip_1hr_metric"]);
    }
    
    // pressure.
    pressure = SETTING_IS(kPressureMeasureSetting, kPressureMeasureInchHg) ?
        FMT(@"%@ inHg", r[@"pressure_in"])                                 :
        FMT(@"%@ inHg", r[@"pressure_mb"]);

    // UV index.
    float safeUV = temp_safe(r[@"UV"]);
    if (safeUV != TEMP_NONE && safeUV > 0)
        uv = r[@"UV"];

    // miles.
    if (SETTING_IS(kDistanceMeasureSetting, kDistanceMeasureMiles)) {
        
        // wind in miles.   (using floatValue forces minimum number of decimals)
        if ([r[@"wind_mph"] floatValue] > 0) {
            windSpeed     = FMT(@"%@ mph", @( [r[@"wind_mph"] floatValue] ));
            windDirection = FMT(@"%@ %@º", r[@"wind_dir"], r[@"wind_degrees"]);
        }
        
        // gusts in miles.
        if ([r[@"wind_gust_mph"] floatValue] > 0)
            gustSpeed     = FMT(@"%@ mph", @( [r[@"wind_gust_mph"] floatValue] ));
        
        // visibility in miles.
        if ([r[@"visibility_mi"] floatValue] > 0)
            visibility = FMT(@"%@ mi", r[@"visibility_mi"]);
        
    }
    
    // kilometers.
    else {

        // wind in km/h.   (using floatValue forces minimum number of decimals)
        if ([r[@"wind_kph"] floatValue] > 0) {
            windSpeed     = FMT(@"%@ km/hr", @( [r[@"wind_kph"] floatValue] ));
            windDirection = FMT(@"%@ %@º", r[@"wind_dir"], r[@"wind_degrees"]);
        }
        
        // gusts in km.
        if ([r[@"wind_gust_kph"] floatValue] > 0)
            gustSpeed = FMT(@"%@ km/hr", @( [r[@"wind_gust_kph"] floatValue] ));
        
        // visibility in km.
        if ([r[@"visibility_km"] floatValue] > 0)
            visibility = FMT(@"%@ km", r[@"visibility_km"]);
        
    }
    
    // compiled list of cell information.
    NSArray *details = @[
        @"Temperature",         FMT(@"%@%@", [self temperature:1], self.tempUnit),
        @"Feels like",          FMT(@"%@%@", [self feelsLike:1],   self.tempUnit),
        @"Dew point",           dewPoint,
        @"Heat index",          heatIndex,
        @"Windchill",           windchill,
        @"Pressure",            pressure,
        @"Humidity",            r[@"relative_humidity"],
        @"Visibility",          visibility,
        @"Precip. today",       precipT,
        @"Precip. in hour",     precipH,
        @"Wind speed",          windSpeed,
        @"Wind direction",      windDirection,
        @"Gust speed",          gustSpeed,
        @"UV index",            uv,
        @"Time at location",    FMT(@"%@ %@", [rfmt stringFromDate:[NSDate date]], self.timeZone.abbreviation),
        @"Last observation",    [fmt stringFromDate:self.observationsAsOf],
        @"Last fetch",          [fmt stringFromDate:self.conditionsAsOf],
        @"Elevation",           r[@"display_location"][@"elevation"] ?
                FMT(@"%.f m", [r[@"display_location"][@"elevation"] floatValue]) : @"NA",
        @"Latitude",            FMT(@"%f", self.latitude),
        @"Longitude",           FMT(@"%f", self.longitude)
    ];
    
    // filter out the "NA" values.
    for (NSUInteger i = 0; i < [details count]; i += 2) {
        if ([details[i + 1] isEqual:@"NA"]) continue;
        [final addObject:@[ details[i], details[i + 1] ]];
    }
    
    self.extensiveDetails = final;
}

#pragma mark - Daily forecast

// recompile daily forecast information.
- (void)updateDailyForecast {
    NSMutableArray *a = [NSMutableArray array];
    for (unsigned int i = 0; i < [self.forecastResponse count]; i++)
        [a addObject:[self forecastForDay:self.forecastResponse[i] index:i]];
    self.dailyForecast = a;
}

// recompile a single day for the daily forecast.
- (NSDictionary *)forecastForDay:(NSDictionary *)f index:(unsigned int)i {
    if (!fakeLocations) fakeLocations = [NSMutableArray array];

    // create a fake location for the cell.
    WALocation *location;
    if ([fakeLocations count] >= i + 1)
        location = fakeLocations[i];
    else
        location = fakeLocations[i] = [WALocation new];
    
    location.loading = NO;
    location.initialLoadingComplete = YES;
    
    // temperatures.
    location.degreesC = temp_safe(f[@"low"][@"celsius"]);
    location.degreesF = temp_safe(f[@"low"][@"fahrenheit"]);
    location.highC    = temp_safe(f[@"high"][@"celsius"]);
    location.highF    = temp_safe(f[@"high"][@"fahrenheit"]);
    
    // is this today?
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *dateComponents = [gregorian components:NSCalendarUnitDay fromDate:[NSDate date]];
    BOOL today = dateComponents.day == [f[@"date"][@"day"] integerValue];
    
    // conditions.
    location.conditions     = f[@"conditions"];
    location.conditionsAsOf = [NSDate date];
    
    // icon.
    location.response = @{
        @"icon":        f[@"icon"],
        @"icon_url":    f[@"icon_url"]
    };
    [location fetchIcon];
    
    // cell background.
    [location updateBackgroundBoth:NO];
    
    NSString *windSpeed, *gustSpeed, *rainfall, *daytimeRainfall, *nighttimeRainfall,
    *snowfall, *daytimeSnowfall, *nighttimeSnowfall, *pop;
    windSpeed = gustSpeed = rainfall = daytimeRainfall = nighttimeRainfall = snowfall =
    daytimeSnowfall = nighttimeSnowfall = pop = @"NA";

    // wind.
    if ([f[@"avewind"][@"kph"] floatValue] > 0) {
        
        // wind info in miles.
        if (SETTING_IS(kDistanceMeasureSetting, kDistanceMeasureMiles)) {
            windSpeed = FMT(@"%@ mph", f[@"avewind"][@"mph"]);
            gustSpeed = FMT(@"%@ mph", f[@"maxwind"][@"mph"]);
        }
        
        // wind info in kilometers.
        else {
            windSpeed = FMT(@"%@ km/hr", f[@"avewind"][@"kph"]);
            gustSpeed = FMT(@"%@ km/hr", f[@"maxwind"][@"kph"]);
        }

    }
    
    /* rain and snow. this is the most hideous I've ever written, but it works.
        NOTE: the QPFs sometimes simply do not make sense. It's not my fault.
        Sometimes they just don't add up. Snowfall seems to be the same way.
        It's Wunderground's fault. http://www.wxforum.net/index.php?topic=15513.0;wap2

        "I don't think the forecast is always accurate and the data doesn't always match up.

        For instance, the rain forecast doesn't always add up. They list a qpf (quantity
        of precipitation forecast) for all day, day, and night in which those hardly add
        up and sometimes a pop is listed with no qpf listed.
        Found some listings of partly cloudy for the am & pm and it shows a qpf.
        Sometimes the temperature forecast is 20 degrees higher for a particular day, as
        compared to the NWS forecast, but later on that forecast will drop to a more
        realistic value.
        Wind gusts usually don't go 5 mph over the average wind speed.

        There is a lot of data provided, but since most of it's inaccurate, it's hard to
        put it on a web page without confusing the visitor."
        
    */
    NSString *unit = SETTING_IS(kPrecipitationMeasureSetting, kPrecipitationMeasureInches)
        ? @"in" : @"mm";
    if (f[@"qpf_allday"] && [f[@"qpf_allday"][unit] floatValue] > 0)
        rainfall = FMT(@"%.2f %@", [f[@"qpf_allday"][unit] floatValue], unit);
    if (f[@"qpf_day"] && [f[@"qpf_day"][unit] floatValue] > 0)
        daytimeRainfall = FMT(@"%.2f %@", [f[@"qpf_day"][unit] floatValue], unit);
    if (f[@"qpf_night"] && [f[@"qpf_night"][unit] floatValue] > 0)
        nighttimeRainfall = FMT(@"%.2f %@", [f[@"qpf_night"][unit] floatValue], unit);
    if (f[@"snow_allday"] && [f[@"snow_allday"][unit] floatValue] > 0)
        snowfall = FMT(@"%.2f %@", [f[@"snow_allday"][unit] floatValue], unit);
    if (f[@"snow_day"] && [f[@"snow_day"][unit] floatValue] > 0)
        daytimeSnowfall = FMT(@"%.2f %@", [f[@"snow_day"][unit] floatValue], unit);
    if (f[@"snow_night"] && [f[@"snow_night"][unit] floatValue] > 0)
        nighttimeSnowfall = FMT(@"%.2f %@", [f[@"snow_night"][unit] floatValue], unit);
    
    // probability of precipitation.
    if (f[@"pop"] && [f[@"pop"] integerValue] > 0) {
        NSString *d;
        NSInteger p = [f[@"pop"] integerValue];
             if (p >= 70) d = @"Very likely";
        else if (p >= 50) d = @"Likely";
        else if (p >= 30) d = @"Chance";
        else if (p >= 20) d = @"Slight chance";
        else              d = @"Unlikely";
        pop = FMT(@"%@ %@%%", d, f[@"pop"]);
    }
    
    // compile a list of details.
    NSArray *details = @[
        @"Maximum temperature",     FMT(@"%@%@", [location highTemp:1], location.tempUnit),
        @"Minimum temperature",     FMT(@"%@%@", [location temperature:1], location.tempUnit),
        @"Wind speed",              windSpeed,
        @"Wind direction",          FMT(@"%@ %@º", f[@"avewind"][@"dir"], f[@"avewind"][@"degrees"]),
        @"Gust speed",              gustSpeed,
        @"Chance of precip.",       pop,
        @"Daytime rainfall",        daytimeRainfall,
        @"Evening rainfall",        nighttimeRainfall,
        @"Total rainfall",          rainfall,
        @"Daytime snowfall",        daytimeSnowfall,
        @"Evening snowfall",        nighttimeSnowfall,
        @"Total snowfall",          snowfall,
        @"Average humidity",        FMT(@"%@%%", f[@"avehumidity"]),
        @"Maximum humidity",        FMT(@"%@%%", f[@"maxhumidity"]),
        @"Minimum humidity",        FMT(@"%@%%", f[@"minhumidity"])
    ];
    
    // filter out the "NA" values.
    NSMutableArray *final = [NSMutableArray array];
    for (NSUInteger i = 0; i < [details count]; i += 2) {
        if ([details[i + 1] isEqual:@"NA"]) continue;
        [final addObject:@[ details[i], details[i + 1] ]];
    }
    
    return @{
        @"location":    location,
        @"cells":       final,
        @"dayName":     today ? @"Today" : f[@"date"][@"weekday"],
        @"dateName":    FMT(@"%@ %@", f[@"date"][@"monthname"], f[@"date"][@"day"])
    };
}

#pragma mark - Hourly forecast

// recompile hourly forecast data.
- (void)updateHourlyForecast {
    self.hourlyForecast = [NSMutableArray array];
    lastDay = currentDayIndex = -1;
    for (unsigned int i = 0; i < [self.hourlyForecastResponse count]; i++)
        [self addHourlyForecastForHour:self.hourlyForecastResponse[i] index:i];
}

// recompile a single hour for hourly forecast.
// format is forecasts[day in month][hour index] = dictionary of info for that hour
// then, the array is shifted so the smallest index becomes 0.
- (void)addHourlyForecastForHour:(NSDictionary *)f index:(unsigned int)i {

    // create a date from the unix time and a gregorian calendar.
    NSDate *date          = [NSDate dateWithTimeIntervalSince1970:[f[@"FCTTIME"][@"epoch"] integerValue]];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    // if setting says to, switch to location's time zone.
    if (SETTING_IS(kTimeZoneSetting, kTimeZoneRemote))
        [gregorian setTimeZone:self.timeZone];
    
    // fetch the information we need.
    NSDateComponents *dateComponents = [gregorian components:NSCalendarUnitDay | NSCalendarUnitHour fromDate:date];
    
    // adjust hour to AM/PM.
    NSUInteger adjustedHour = dateComponents.hour;
    BOOL pm = NO;
    if (adjustedHour >= 12) {
        pm = YES;
        if (adjustedHour > 12) adjustedHour -= 12;
    }
    if (adjustedHour == 0) adjustedHour = 12;

    NSUInteger dayIndex = dateComponents.day;
    
    // the day has changed.
    if (dayIndex != lastDay) {
        currentDayIndex++;
        lastDay = dayIndex;
    }
    
    // this day does not yet exist.
    if ([self.hourlyForecast count] == 0 || currentDayIndex > [self.hourlyForecast count] - 1) {
    
        // determine the day name.
        NSDateFormatter *formatter = [NSDateFormatter new];
        if (SETTING_IS(kTimeZoneSetting, kTimeZoneRemote))
            [formatter setTimeZone:self.timeZone];
        NSString *dayName, *dateName;

        // determine day of week.
        formatter.dateFormat = @"EEEE";
        dayName = [formatter stringFromDate:date];

        // this is today in our local timezone.
        // in other words, the day in the month is equal in both locations,
        // so we will say "Today."
        [gregorian setTimeZone:[NSTimeZone localTimeZone]];
        NSUInteger today = [gregorian components:NSCalendarUnitDay fromDate:[NSDate date]].day;
        if (today == dateComponents.day)
            dayName = @"Today";

        // determine the date string.
        formatter.dateFormat = @"MMMM d";
        dateName = [formatter stringFromDate:date];
        
        // create the day array with the name as the first object.
        [self.hourlyForecast addObject:[NSMutableArray arrayWithObject:@[dayName, dateName]]];
        
    }
    NSMutableArray *day = self.hourlyForecast[currentDayIndex];
    
    // create a fake location for the icons and temperatures.
    WALocation *location = [[self class] new];
    location.response = @{
        @"icon":        f[@"icon"],
        @"icon_url":    f[@"icon_url"]
    };
    location.degreesC = temp_safe(f[@"temp"][@"metric"]);
    location.degreesF = temp_safe(f[@"temp"][@"english"]);
    [location fetchIcon];
    
    // pretty attributed hour.
    NSString *hourString = FMT(@"%ld %@", (long)adjustedHour, pm ? @"pm" : @"am");
    NSMutableAttributedString *prettyHour = [[NSMutableAttributedString alloc] initWithString:hourString];
    NSRange range = NSMakeRange([hourString length] - 2, 2);
    [prettyHour addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14] range:range];
    
    // information we care about.
    [day addObject:@{
        @"prettyHour":      prettyHour,
        @"iconImage":       [UIImage imageNamed:FMT(@"icons/30/%@", location.conditionsImageName)],
        @"temperature":     location.temperature,
        @"condition":       f[@"condition"]
        //@"date":            date,
        //@"dateComponents":  dateComponents,
        //@"adjustedHour":    @(adjustedHour),
        //@"pm":              @(pm),
        //@"hourString":      hourString,
        //@"iconName":        location.conditionsImageName,
        //@"icon":            f[@"icon"],
        //@"icon_url":        f[@"icon_url"],
        //@"temp_c":          f[@"temp"][@"metric"],
        //@"temp_f":          f[@"temp"][@"english"],
    }];
    
}

@end
