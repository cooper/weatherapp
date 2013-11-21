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
        NSLog(@"Looking up with %f,%f",     self.latitude, self.longitude);
        q = FMT(@"conditions/q/%f,%f.json", self.latitude, self.longitude);
    }
    
    // use wunderground ID.
    else if ([self.l length]) {
        NSLog(@"Looking up with %@", self.l);
        q = FMT(@"conditions/%@.json", self.l);
    }
    
    // use the preferred region and city name.
    else {
        NSLog(@"Looking up with %@", self.fullName);
        q = FMT(@"conditions/q/%@/%@.json", URL_ESC(self.region), URL_ESC(self.city));
    }
    
    // fetch the conditions.
    [self fetch:q then:^(NSURLResponse *res, NSDictionary *data, NSError *err) {
        NSDictionary *ob  = data[@"current_observation"];
        NSDictionary *loc = ob[@"display_location"];

        NSLog(@"Got conditions for %@", loc[@"city"]);
        
        // force the view to load if it hasn't already.
        [self.viewController view];
        
        // set our city/region information.
        // note: the setters ignore any lengthless value.
        // the setters call the interface methods to make changes.
        self.city         = loc[@"city"];
        self.countryCode  = loc[@"country"];
        self.country3166  = loc[@"country_iso3166"];
        self.region       = OR(loc[@"state_name"], loc[@"country"]);
        
        // don't use wunderground's coordinates if this is the current location,
        // because those reported by location services are far more accurate.
        if (!self.isCurrentLocation) {
            self.latitude     = [loc[@"latitude"]  floatValue];
            self.longitude    = [loc[@"longitude"] floatValue];
        }
        
        
        // round temperatures to the nearest whole degree.
        self.degreesC = lroundf([ob[@"temp_c"] floatValue]);
        self.degreesF = lroundf([ob[@"temp_f"] floatValue]);
        
        self.conditions = ob[@"weather"];
        
        // if an icon is included in the response, use it.
        // if the weather API icon contains "/nt", use a nighttime icon.
        if (ob[@"icon"]) {
            BOOL nightTime       = [ob[@"icon_url"] rangeOfString:@"/nt"].location != NSNotFound;
            NSString *image      = IS_IPAD ? FMT(@"%@-ipad", ob[@"icon"]) : ob[@"icon"];
            self.conditionsImage = [UIImage imageNamed:FMT(@"icons/%@%@", nightTime ? @"nt_" : @"", image]);
                                    
            // if it's nighttime and the image does not exist, fall back to a daytime image.
            if (nightTime && !self.conditionsImage)
                self.conditionsImage = [UIImage imageNamed:FMT(@"icons/%@", image)];
                                    
        }
        
        // if we don't have that icon, download wunderground's.
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

#pragma mark - Location properties

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

- (void)setRegion:(NSString *)region {
    if (![region length]) return;
    _region = region;
    [self.viewController updateRegionTitle:region];
    [self.viewController updateFullTitle:self.fullName];
}

#pragma mark - Automatic properties

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

#pragma mark - User defaults

- (NSDictionary *)userDefaultsDict {
    NSArray * const keys = @[
        @"city",                @"l",
        @"countryCode",         @"country3166",
        @"regionCode",          @"region",
        @"isCurrentLocation",   @"locationAsOf",
        @"latitude",            @"longitude",
        @"conditions",          @"conditionsAsOf",
        @"degreesC",            @"degreesF"
    ];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    for (NSString *key in keys)
        if ([self valueForKey:key]) dict[key] = [self valueForKey:key];
    
    return dict;
}

@end
