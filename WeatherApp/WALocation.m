//
//  WALocation.m
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/28/13.
//  Copyright (c) 2013-14 Mitchell Cooper. All rights reserved.
//

#import "WALocation.h"
#import "WAWeatherVC.h"
#import "WALocationManager.h"
#import "WANavigationController.h"
#import "WALocationListTVC.h"
#import "WAPageViewController.h"
#import "UIImage+Preload.h"

@implementation WALocation

- (id)init {
    self = [super init];
    if (self) {
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
    WALocation *location = [[self alloc] init];
    location.dummy = YES;
    return location;
}

#pragma mark - Fetching data

- (void)fetchCurrentConditions {
    [self fetchCurrentConditionsThen:nil];
}

// fetches and updates the current weather conditions of the location.
- (void)fetchCurrentConditionsThen:(WACallback)then {
    [self fetchThreeDayForecast];
    NSString *q = [self bestLookupMethod:@"conditions"];
    
    // fetch the conditions.
    // todo: err handling, call endLoading in err.
    [self beginLoading];
    [self fetch:q then:^(NSURLResponse *res, NSDictionary *data, NSError *err) {
        
        NSDictionary *ob  = data[@"current_observation"];
        NSDictionary *loc = ob[@"display_location"];

        NSLog(@"Got conditions for %@", loc[@"city"]);
        
        // force the view to load if it hasn't already.
        [self.viewController view];
        
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
        
        // don't use wunderground's coordinates if this is the current location,
        // because those reported by location services are far more accurate.
        if (!self.isCurrentLocation) {
            self.latitude     = [loc[@"latitude"]  floatValue];
            self.longitude    = [loc[@"longitude"] floatValue];
        }
        
        // reset temperatures.
        self.degreesC   = self.degreesF   =
        self.feelsLikeC = self.feelsLikeF =
        self.heatIndexC = self.heatIndexF =
        self.windchillC = self.windchillF = TEMP_NONE;
        
        // temperatures.
        // no longer round temperatures to the nearest whole degree here.
        
        self.degreesC   = [ob[@"temp_c"]       floatValue];
        self.degreesF   = [ob[@"temp_f"]       floatValue];
        self.feelsLikeC = [ob[@"feelslike_c"]  floatValue];
        self.feelsLikeF = [ob[@"feelslike_f"]  floatValue];
        
        // dew point. (NSString = NA)
        if (ob[@"dewpoint_c"] && [ob[@"dewpoint_c"] isMemberOfClass:[NSNumber class]]) {
            self.dewPointC  = [ob[@"dewpoint_c"]   floatValue];
            self.dewPointF  = [ob[@"dewpoint_f"]   floatValue];
        }
        
        // heat index. (NSString = NA)
        if (ob[@"heat_index_c"] && ![ob[@"heat_index_c"] isMemberOfClass:[NSNumber class]]) {
            self.heatIndexC = [ob[@"heat_index_c"] floatValue];
            self.heatIndexF = [ob[@"heat_index_f"] floatValue];
        }
        
        // windchill. (NSString = NA)
        if (ob[@"windchill_c"] && ![ob[@"windchill_c"] isMemberOfClass:[NSNumber class]]) {
            self.windchillC = [ob[@"windchill_c"] floatValue];
            self.windchillF = [ob[@"windchill_f"] floatValue];
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
        
        [self endLoading];
        
        // execute callback.
        if (then) then();
        
    }];
    
}

// three-day forecast.
- (void)fetchThreeDayForecast {
    NSString *q = [self bestLookupMethod:@"forecast"];
    [self fetch:q then:^(NSURLResponse *res, NSDictionary *data, NSError *err) {
        self.forecast = data[@"forecast"][@"simpleforecast"][@"forecastday"];
        self.textForecast = data[@"forecast"][@"txt_forecast"][@"forecastday"];
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
            if (!data) return;
            self.conditionsImage = [UIImage imageWithData:data];
            [self endLoading];
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
    
    // create a request for the weather underground API.
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:FMT(@"http://api.wunderground.com/api/" WU_API_KEY @"/%@", page)]];
    
    // send a request asyncrhonously.
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {

        // an error occurred.
        if (connectionError || !data) {
            NSLog(@"Fetch error: %@", connectionError ? connectionError : @"unknown");
            return;
        }
        
        NSError *error;
        id jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        
        // an error occurred.
        if (error) {
            NSLog(@"Error decoding JSON response: %@", error);
            return;
        }
        
        // ensure that the data is a dictionary (JSON object).
        if (![jsonData isKindOfClass:[NSDictionary class]]) {
            NSLog(@"JSON response is not of object type.");
            return;
        }
        
        // everything looks well; go ahead and fire the callback.
        callback(response, jsonData, connectionError);
        NSLog(@"json: %@", jsonData);
        
        // update the database.
        [APP_DELEGATE saveLocationsInDatabase];
        
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

- (NSString *)temperature {
    float t;
    if (SETTING_IS(kTemperatureScaleSetting, kTemperatureScaleFahrenheit))
        t = self.degreesF;
    else if (SETTING_IS(kTemperatureScaleSetting, kTemperatureScaleKelvin))
        t = self.degreesC + 273.15;
    else
        t = self.degreesC;
    
    return [NSString stringWithFormat:@"%.f", t];
}

- (NSString *)feelsLike {
    float t;
    if (SETTING_IS(kTemperatureScaleSetting, kTemperatureScaleFahrenheit))
        t = self.feelsLikeF;
    else if (SETTING_IS(kTemperatureScaleSetting, kTemperatureScaleKelvin))
        t = self.feelsLikeC + 273.15;
    else
        t = self.feelsLikeC;
    
    return [NSString stringWithFormat:@"%.f", t];
}

- (NSString *)dewPoint {
    float t;
    if (SETTING_IS(kTemperatureScaleSetting, kTemperatureScaleFahrenheit))
        t = self.dewPointF;
    else if (SETTING_IS(kTemperatureScaleSetting, kTemperatureScaleKelvin))
        t = self.dewPointC + 273.15;
    else
        t = self.dewPointC;
    
    return [NSString stringWithFormat:@"%.f", t];
}

- (NSString *)heatIndex {
    float t;
    if (SETTING_IS(kTemperatureScaleSetting, kTemperatureScaleFahrenheit))
        t = self.heatIndexF;
    else if (SETTING_IS(kTemperatureScaleSetting, kTemperatureScaleKelvin))
        t = self.heatIndexC + 273.15;
    else
        t = self.heatIndexC;
    
    return [NSString stringWithFormat:@"%.f", t];
}

- (NSString *)windchill {
    float t;
    if (SETTING_IS(kTemperatureScaleSetting, kTemperatureScaleFahrenheit))
        t = self.heatIndexF;
    else if (SETTING_IS(kTemperatureScaleSetting, kTemperatureScaleKelvin))
        t = self.heatIndexC + 273.15;
    else
        t = self.heatIndexC;
    
    return [NSString stringWithFormat:@"%.f", t];
}

- (NSString *)tempUnit {
    if (SETTING_IS(kTemperatureScaleSetting, kTemperatureScaleFahrenheit))
        return @"ºF";
    else if (SETTING_IS(kTemperatureScaleSetting, kTemperatureScaleKelvin))
        return @"K";
    else return @"ºC";
}

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
    [APP_DELEGATE beginActivity];
    
    // if pageVC exists, update its navigation bar.
    // (to add indicator in place of refresh button)
    if (APP_DELEGATE.pageVC) [APP_DELEGATE.pageVC updateNavigationBar];
    
}

// indicates finish loading.
- (void)endLoading {
    self.loading = NO;
    
    // create the view controller.
    if (!self.initialLoadingComplete) {
        WAWeatherVC *weatherVC = [[WAWeatherVC alloc] initWithNibName:@"WAWeatherVC" bundle:nil];
        self.viewController = weatherVC;
        weatherVC.location  = self;         // weak
        self.initialLoadingComplete = YES;
    }
    
    // stop the status bar indicator.
    [APP_DELEGATE endActivity];
    
    // update the weather view controller's info.
    [self updateBackground];
    [self.viewController update];
    
    // if the location list TVC exists, update the cell for this location.
    WANavigationController *nc = APP_DELEGATE.nc;
    if (nc && nc.tvc) [nc.tvc updateLocationAtIndex:self.index];
    
    // if the pageVC exists, update the navigation bar.
    // (replace loading indicator with refresh button)
    if (APP_DELEGATE.pageVC) [APP_DELEGATE.pageVC updateNavigationBar];
    
}

#pragma mark - Backgrounds

- (void)updateBackground {
    return [self updateBackgroundBoth:YES];
}

- (void)updateBackgroundBoth:(BOOL)both {
    NSLog(@"update background on %@", self.city);
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
    if ([self.currentBackgroundIcon isEqualToString:self.conditionsImageName] && [self.currentBackgroundConditions isEqualToString:self.conditions])
        NSLog(@"Icon and conditions not changed. Background is same");
    
    // find a background.
    else for (NSDictionary *bg in backgrounds) {
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
                @"name":  bg[@"name"],
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
    
    // UIImage is not thread-safe, so we have to load these in the main queue.
    //dispatch_async(dispatch_get_main_queue(), ^{
    
        // load the full-size background as well.
        if (both) {
            NSString *backgroundFile = [[NSBundle mainBundle] pathForResource:FMT(@"backgrounds/%@", chosenBackground) ofType:@"jpg"];
            self.background = [[UIImage imageWithContentsOfFile:backgroundFile] preloadedImage];
        }

        NSString *cellBackgroundFile = [[NSBundle mainBundle] pathForResource:FMT(@"backgrounds/200/%@", chosenBackground) ofType:@"jpg"];
        self.cellBackground = [[UIImage imageWithContentsOfFile:cellBackgroundFile] preloadedImage];

    //});

}

@end
