//
//  WALocation.m
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/28/13.
//  Copyright (c) 2013 Really Good. All rights reserved.
//

#import "WALocation.h"
#import "WAAppDelegate.h"
#import "WAWeatherVC.h"
#import "WALocationManager.h"

@implementation WALocation

#pragma mark - Fetching data

- (void)fetchCurrentConditions {
    [self fetchCurrentConditionsThen:nil];
}

// fetches and updates the current weather conditions of the location.
- (void)fetchCurrentConditionsThen:(WACallback)then {

    // determine how we will look up this location.
    NSString *q;
    
    // use our coordinates.
    if (self.isCurrentLocation) {
        NSLog(@"Looking up with %f,%f", self.coordinate.latitude, self.coordinate.longitude);
        q = FMT(@"conditions/q/%f,%f.json", self.coordinate.latitude, self.coordinate.longitude);
    }
    
    // use the preferred region and city name.
    else {
        NSLog(@"Looking up with %@, %@", self.safeCity, self.lookupRegion);
        q = FMT(@"conditions/q/%@/%@.json", self.lookupRegion, self.safeCity);
    }
    
    // fetch the conditions.
    [self fetch:q then:^(NSURLResponse *res, NSDictionary *data, NSError *err) {
        NSLog(@"Got conditions for %@", data[@"current_observation"][@"display_location"][@"city"]);
        
        // force the view to load if it hasn't already.
        [self.viewController view];
        
        // set our city/region information.
        // note: the setters ignore any lengthless value.
        //  the setters call the interface methods to make changes.
        NSDictionary *loc = data[@"current_observation"][@"display_location"];
        
        self.city         = loc[@"city"];
        self.countryShort = loc[@"country"];
        
        // In the United States, use states.
        if ([loc[@"country"] isEqualToString:@"US"]) {
            self.state        = loc[@"state_name"];
            self.stateShort   = loc[@"state"];
        }
        
        NSDictionary *ob = data[@"current_observation"];
        // I really don't like when Wunderground shortens formal names to short
        // names. For example, I don't wanted United Arab Emirates shortened to UAE.
        
        // I also don't like how it pointlessly says that Beijing and Shanghai are
        // countries. They, quite frankly, are actually cities. I would understand
        // why Hong Kong and Macau may be classified as countries, but Shanghai and
        // Beijing most definitely should not. (update: it was actually saying state)
        
        // Because of these annoyances, I'm only setting country from Wunderground if
        // it has not been determined by the lookup/suggestion service.
        
        // This should not be an issue anyway, since Wunderground obviously
        // understands what I mean anyway when it "corrects" my "mistakes."
        
        if (!self.country || self.isCurrentLocation)
            self.country = loc[@"country_name"];
        
        // don't use wunderground's coordinates if this is the current location,
        // because those reported by location services are far more accurate.
        if (!self.isCurrentLocation) {
            self.latitude     = [loc[@"latitude"]  floatValue];
            self.longitude    = [loc[@"longitude"] floatValue];
        }
        
        // round temperatures to the nearest whole degree.
        self.degreesC = lroundf([(NSNumber *)ob[@"temp_c"] floatValue]);
        self.degreesF = lroundf([(NSNumber *)ob[@"temp_f"] floatValue]);
        
        self.conditions = ob[@"weather"];
        
        
        // if an icon is included in the response, use it.
        if (ob[@"icon"]) self.conditionsImage = [UIImage imageNamed:FMT(@"icons/%@", ob[@"icon"])];
        if (ob[@"icon_url"] && !self.conditionsImage) {
            NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:ob[@"icon_url"]]];
            [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                if (!data) return;
                self.conditionsImage = [UIImage imageWithData:data];
                [APP_DELEGATE changedLocationAtIndex:self.index];
            }];
        }
        
        // update time of last conditions check.
        self.conditionsAsOf = [NSDate date];

        [APP_DELEGATE changedLocationAtIndex:self.index];
        if (then) then();
        
    }];
    
}

- (void)fetchThreeDayForecast {
}


// find the city and state based on coordinates.
- (void)fetchGeolocation:(WACallback)then {
    
    // if this location has no coordinates, we cannot continue.
    if (!self.coordinate.latitude) {
        NSLog(@"Fetching geolocation before coordinates available");
        return;
    }
    
    // already looking it up.
    if (inGeoLookup) {
        NSLog(@"Ignoring geolookup request because we're doing one already");
        return;
    }
    
    inGeoLookup = YES;
    
    NSString *q = FMT(@"geolookup/q/%f,%f.json", self.coordinate.latitude, self.coordinate.longitude);
    [self fetch:q then:^(NSURLResponse *res, NSDictionary *data, NSError *err) {
        // TODO: what if nothing is found? is that possible?
        self.city         = data[@"location"][@"city"];
        self.stateShort   = data[@"location"][@"state"];
        self.state        = data[@"location"][@"state_name"];
        self.countryShort = data[@"location"][@"country"];
        self.country      = data[@"location"][@"country_name"];
        NSLog(@"Got city: %@, regionShort: %@", self.city, self.regionShort);
        inGeoLookup = NO;
        if (then) then();

    }];
    
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
        //NSLog(@"json: %@", jsonData);
        
        // update the database.
        [APP_DELEGATE saveLocationsInDatabase];
        
    }];
}

#pragma mark - Current location properties

// NOTE: these getters are disabled because they are synthesized.
// currently, the properties are nonatomic. if for some reason
// it becomes necessary for them to be atomic, enable these getters.

// coordinate property setter allows us to update the coordinate.



#pragma mark - City/region/country properties

- (void)setCoordinate:(CLLocationCoordinate2D)coordinate {
    self.latitude  = coordinate.latitude;
    self.longitude = coordinate.longitude;
    [self.viewController updateLatitude:coordinate.latitude longitude:coordinate.longitude];
}

// coordinate getter.
- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake(self.latitude, self.longitude);
}

- (void)setLatitude:(float)latitude {
    _latitude = latitude;
    [self.viewController updateLatitude:latitude longitude:self.longitude];
}

- (void)setLongitude:(float)longitude {
    _longitude = longitude;
    [self.viewController updateLatitude:self.latitude longitude:longitude];
}

- (void)setCity:(NSString *)city {
    if (![city length]) return;
    _city = city;
    [self.viewController updateLocationTitle:self.city];
    [self.viewController updateFullTitle:self.fullName];
}

- (void)setState:(NSString *)state {
    if (![state length]) return;
    _state = state;
    [self.viewController updateRegionTitle:self.region];
    [self.viewController updateFullTitle:self.fullName];
}

- (void)setStateShort:(NSString *)stateShort {
    if (![stateShort length]) return;
    _stateShort = stateShort;
}

- (void)setCountry:(NSString *)country {
    if (![country length]) return;
    _country = country;
}

- (void)setCountryShort:(NSString *)countryShort {
    if (![countryShort length]) return;
    _countryShort = countryShort;
}

#pragma mark - Automatic properties

// automatic.

- (NSString *)region {
    return OR(self.state, self.country);
}

- (NSString *)regionShort {
    return OR(self.stateShort, self.countryShort);
}

- (NSString *)fullName {
    if (!self.city || !self.region) return nil;
    return FMT(@"%@, %@", self.city, self.region);
}

- (NSUInteger)index {
    return [self.manager.locations indexOfObject:self];
}

#pragma mark - Current condition properties

- (void)setDegreesC:(float)degreesC {
    _degreesC = degreesC;
    [self.viewController updateTemperature:degreesC fahrenheit:self.degreesF];
}

- (void)setDegreesF:(float)degreesF {
    _degreesF = degreesF;
    [self.viewController updateTemperature:self.degreesC fahrenheit:degreesF];
}

- (void)setConditions:(NSString *)conditions {
    if (![conditions length]) return;
    _conditions = conditions;
    [self.viewController updateConditions:conditions];
}

#pragma mark - Safe properties

// TODO: I honestly think all of these can be removed.

- (NSString *)safeCity {
    return URL_ESC(self.city);
}

- (NSString *)safeRegion {
    return URL_ESC(self.region);
}

- (NSString *)safeRegionShort {
    return URL_ESC(self.regionShort);
}

- (NSString *)lookupRegion {
    if (self.stateShort) return URL_ESC(self.stateShort);
    return self.country ? URL_ESC(self.country) : URL_ESC(self.regionShort);
}

#pragma mark - User defaults

- (NSDictionary *)userDefaultsDict {
    NSArray * const keys = @[
        @"city",
        @"state", @"stateShort",
        @"country", @"countryShort",
        @"isCurrentLocation", @"locationAsOf",
        @"latitude", @"longitude",
        @"conditions", @"conditionsAsOf",
        @"degreesC", @"degreesF"
    ];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    for (NSString *key in keys)
        if ([self valueForKey:key]) dict[key] = [self valueForKey:key];
    
    return dict;
}

@end
