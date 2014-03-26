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

- (id)init {
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

- (void)fetchCurrentConditions {
    [self fetchCurrentConditionsThen:nil];
}

// fetches and updates the current weather conditions of the location.
- (void)fetchCurrentConditionsThen:(WACallback)then {
    NSString *q = [self bestLookupMethod:@"conditions"];
    
    // fetch the conditions.
    [self fetch:q then:^(NSURLResponse *res, NSDictionary *data, NSError *err) {
        
        NSDictionary *ob  = data[@"current_observation"];
        NSDictionary *loc = ob[@"display_location"];

        NSLog(@"Got conditions for %@", loc[@"city"]);
        
        // force the view to load if it hasn't already.
        [self.overviewVC view];
        
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
        
        // execute callback.
        if (then) then();
        
    }];
    
}

// ten-day forecast. TODO: handle errors.
- (void)fetchForecast {
    NSString *q = [self bestLookupMethod:@"forecast10day"];
    [self fetch:q then:^(NSURLResponse *res, NSDictionary *data, NSError *err) {
        self.forecastResponse = data[@"forecast"][@"simpleforecast"][@"forecastday"];
        // make sure forecast10day is true
        [self updateDailyForecast];
        self.dailyForecastAsOf = [NSDate date];
    }];
}

// hourly forecast. TODO: handle errors.
- (void)fetchHourlyForecast:(BOOL)tenDay {
    NSString *q = [self bestLookupMethod:tenDay ? @"hourly10day" : @"hourly"];
    [self fetch:q then:^(NSURLResponse *res, NSDictionary *data, NSError *err) {
        // make sure hourly10day is true
        self.hourlyForecastResponse = data[@"hourly_forecast"];
        [self updateHourlyForecast];
        self.hourlyForecastAsOf = [NSDate date];
    }];
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

// send a request to the API. runs asynchronously, decodes JSON,
// and then executes the callback with an dictionary argument in main queue.
- (void)fetch:(NSString *)page then:(WALocationCallback)callback {
    [self beginLoading];
    
    // create a request for the weather underground API.
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:FMT(@"http://api.wunderground.com/api/" WU_API_KEY @"/%@", page)]];
    
    // send a request asyncrhonously.
    [NSURLConnection sendAsynchronousRequest:request queue:self.manager.queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {

        // an error occurred.
        if (connectionError || !data) {
            NSLog(@"Fetch error: %@", connectionError ? connectionError : @"unknown");
            [self handleError:connectionError.localizedDescription];
            return;
        }
        
        NSError *error;
        id jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        
        // an error occurred.
        if (error) {
            NSLog(@"Error decoding JSON response: %@", error);
            [self handleError:@"Error decoding JSON response: %@"];
            return;
        }
        
        // ensure that the data is a dictionary (JSON object).
        if (![jsonData isKindOfClass:[NSDictionary class]]) {
            NSLog(@"JSON response is not of object type.");
            [self handleError:@"JSON response is not of object type."];
            return;
        }
        
        // everything looks well; go ahead and fire the callback in main queue.
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            callback(response, jsonData, connectionError);
            
            [self endLoading];
        
            // update the database.
            [appDelegate saveLocationsInDatabase];
        
        }];
    
    }];
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
        return FMT(FMT(@"%%.%df", decimalPlaces), t);                           \
    }

tempFunction(temperature, degreesC,   degreesF)
tempFunction(windchill,   windchillC, windchillF)
tempFunction(heatIndex,   heatIndexC, heatIndexF)
tempFunction(dewPoint,    dewPointC,  dewPointF)
tempFunction(highTemp,    highC,      highF)
tempFunction(feelsLike,   feelsLikeC, feelsLikeF)

#pragma mark - User defaults

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
    if (appDelegate.pageVC) [appDelegate.pageVC updateNavigationBar];
    
}

// indicates finish loading.
- (void)endLoading {
    self.loading = NO;
    
    // create the view controller.
    if (!self.initialLoadingComplete) {
        self.overviewVC = [[WAWeatherVC alloc] initWithLocation:self];
        self.initialLoadingComplete = YES;
    }
    
    // stop the status bar indicator.
    [appDelegate endActivity];
    
    // update the weather view controller's info.
    [self updateBackground];
    
    if (self.overviewVC) [self.overviewVC update];
    if (self.detailVC)   [self.detailVC   update];
    if (self.hourlyVC)   [self.hourlyVC   update];
    if (self.dailyVC)    [self.dailyVC    update];
    
    // if the location list TVC exists, update the cell for this location.
    WANavigationController *nc = appDelegate.nc;
    if (nc && nc.tvc) [nc.tvc updateLocationAtIndex:self.index];
    
    // if the pageVC exists, update the navigation bar.
    // (replace loading indicator with refresh button)
    if (appDelegate.pageVC) [appDelegate.pageVC updateNavigationBar];
    
}


// handle an error.
- (void)handleError:(NSString *)errstr {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:FMT(@"%@ error", OR(self.city, @"Location")) message:errstr delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alert show];
    [self endLoading];
}

#pragma mark - Backgrounds

- (void)updateBackground {
    return [self updateBackgroundBoth:YES];
}

- (void)updateBackgroundBoth:(BOOL)both {

    // in order by priority. the first match wins.
    
    // matching is case-insensitive. night is preferred if it's night time,
    // but if a night array does not exist, day acts as a fallback.
    
    // the background selector alternates through each array by storing
    // the last-used index in the user defaults database.
    
    // load backgrounds from plist.
    NSString *bgPlist    = [[NSBundle mainBundle] pathForResource: @"backgrounds" ofType: @"plist"];
    NSArray *backgrounds = [NSArray arrayWithContentsOfFile:bgPlist];
    
    // if the icon and conditions haven't changed, don't waste energy analyzing backgrounds.
    unsigned int i = 0; NSDictionary *selection;
    if (![self.currentBackgroundIcon isEqualToString:self.conditionsImageName] ||
        ![self.currentBackgroundConditions isEqualToString:self.conditions])
        
    // one or both have changed.
    for (NSDictionary *bg in backgrounds) {
    
        // search for matches.
        BOOL matchesIcon = bg[@"icon"] && [self.conditionsImageName rangeOfString:bg[@"icon"] options:NSCaseInsensitiveSearch].location != NSNotFound;
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
    if ([self.currentBackgroundName isEqualToString:selection[@"name"]] && self.currentBackgroundTimeOfDay == [selection[@"night"] boolValue])
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
    
    self.currentBackgroundName       = selection[@"name"];
    self.currentBackgroundIcon       = self.conditionsImageName;
    self.currentBackgroundConditions = self.conditions;
    self.currentBackgroundTimeOfDay  = [selection[@"night"] boolValue];
    
    // load the full-size background as well.
    if (both) {
        NSString *backgroundFile = [[NSBundle mainBundle] pathForResource:FMT(@"backgrounds/%@", chosenBackground) ofType:@"jpg"];
        self.background = [[UIImage imageWithContentsOfFile:backgroundFile] preloadedImage];
    }

    NSString *cellBackgroundFile = [[NSBundle mainBundle] pathForResource:FMT(@"backgrounds/200/%@", chosenBackground) ofType:@"jpg"];
    self.cellBackground = [[UIImage imageWithContentsOfFile:cellBackgroundFile] preloadedImage];
    
}

#pragma mark - Daily forecast

- (void)updateDailyForecast {
    NSMutableArray *a = [NSMutableArray array];
    for (unsigned int i = 0; i < [self.forecastResponse count]; i++)
        [a addObject:[self forecastForDay:self.forecastResponse[i] index:i]];
    self.dailyForecast = a;
}

- (NSArray *)forecastForDay:(NSDictionary *)f index:(unsigned int)i {
    NSMutableArray *a = [NSMutableArray array];
    if (!self.fakeLocations) self.fakeLocations = [NSMutableArray array];

    // create a fake location for the cell.
    WALocation *location;
    if ([self.fakeLocations count] >= i + 1)
        location = self.fakeLocations[i];
    else
        location = self.fakeLocations[i] = [WALocation new];
    
    location.loading = NO;
    location.initialLoadingComplete = YES;
    
    // temperatures.
    location.degreesC = [f[@"low"][@"celsius"]      floatValue];
    location.degreesF = [f[@"low"][@"fahrenheit"]   floatValue];
    location.highC    = [f[@"high"][@"celsius"]     floatValue];
    location.highF    = [f[@"high"][@"fahrenheit"]  floatValue];
    
    // is this today?
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *dateComponents = [gregorian components:NSDayCalendarUnit fromDate:[NSDate date]];
    BOOL today = dateComponents.day == [f[@"date"][@"day"] integerValue];
    
    // location (time).
    location.city     = today ? @"Today" : f[@"date"][@"weekday"];
    location.region   = FMT(@"%@ %@", f[@"date"][@"monthname_short"], f[@"date"][@"day"]);

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
    
    // other detail cells.↑%@↓
    [a addObjectsFromArray:@[
        @[@"Temperature",  FMT(@"↑%@%@ ↓%@%@", location.highTemp, location.tempUnit, location.temperature, location.tempUnit)],
        @[@"Humidity",     FMT(@"~%@%% ↑%@%% ↓%@%%", f[@"avehumidity"], f[@"maxhumidity"], f[@"minhumidity"])],
    ]];
    
    
    // wind.
    if ([f[@"avewind"][@"kph"] floatValue] > 0) {
        
        // wind info in miles.
        if (SETTING_IS(kDistanceMeasureSetting, kDistanceMeasureMiles)) [a addObjectsFromArray:@[
            @[@"Wind",  FMT(@"%@ %@º %@ mph", f[@"maxwind"][@"dir"], f[@"maxwind"][@"degrees"], f[@"avewind"][@"mph"])],
            @[@"Gusts", FMT(@"%@ %@º %@ mph", f[@"maxwind"][@"dir"], f[@"maxwind"][@"degrees"], f[@"maxwind"][@"mph"])]
        ]];
        
        // wind info in kilometers.
        else [a addObjectsFromArray:@[
            @[@"Wind",  FMT(@"%@ %@º %@ km/hr", f[@"maxwind"][@"dir"], f[@"maxwind"][@"degrees"], f[@"avewind"][@"kph"])],
            @[@"Gusts", FMT(@"%@ %@º %@ km/hr", f[@"maxwind"][@"dir"], f[@"maxwind"][@"degrees"], f[@"maxwind"][@"kph"])]
        ]];

    }
    
    return @[location, a];
}

#pragma mark - Hourly forecast

- (void)updateHourlyForecast {
    self.hourlyForecast = [NSMutableArray array];
    daysAdded = [NSMutableArray array];
    lastDay   = currentDayIndex = -1;
    for (unsigned int i = 0; i < [self.hourlyForecastResponse count]; i++)
        [self addHourlyForecastForHour:self.hourlyForecastResponse[i] index:i];
}

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
    NSDateComponents *dateComponents = [gregorian components:NSDayCalendarUnit | NSHourCalendarUnit fromDate:date];
    
    // adjust hour to AM/PM.
    NSUInteger adjustedHour = dateComponents.hour;
    BOOL pm = NO;
    if (adjustedHour == 0) adjustedHour = 12;
    if (adjustedHour >= 12) {
        pm = YES;
        if (adjustedHour > 12) adjustedHour -= 12;
    }
    
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
        
        // add to list.
        // if it's there already, say "next" weekday,
        // such as "Next Tuesday"
        if ([daysAdded containsObject:dayName])
            dayName = FMT(@"Next %@", dayName);
        else
            [daysAdded addObject:dayName];
        
        // this is today in our local timezone.
        // in other words, the day in the month is equal in both locations,
        // so we will say "Today."
        [gregorian setTimeZone:[NSTimeZone localTimeZone]];
        NSUInteger today = [gregorian components:NSDayCalendarUnit fromDate:[NSDate date]].day;
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
        @"date":            date,
        @"dateComponents":  dateComponents,
        @"adjustedHour":    @(adjustedHour),
        @"pm":              @(pm),
        @"prettyHour":      prettyHour,
        @"iconImage":       [UIImage imageNamed:FMT(@"icons/30/%@", location.conditionsImageName)],
        @"temperature":     location.temperature,
        @"condition":       f[@"condition"]
        //@"hourString":      hourString,
        //@"iconName":        location.conditionsImageName,
        //@"icon":            f[@"icon"],
        //@"icon_url":        f[@"icon_url"],
        //@"temp_c":          f[@"temp"][@"metric"],
        //@"temp_f":          f[@"temp"][@"english"],
    }];
    
}

@end
