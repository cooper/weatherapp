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

@implementation WALocation

#pragma mark - Fetching data

// fetches and updates the current weather conditions of the location.
- (void)fetchCurrentConditions {

    // determine how we will look up this location.
    NSString *q;
    
    // use our coordinates.
    if (self.coordinate.latitude) {
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
        self.state        = loc[@"state_name"];
        self.stateShort   = loc[@"state"];
        self.country      = loc[@"country_name"];
        self.countryShort = loc[@"country"];
        self.fullName     = loc[@"full"];

        
        // round temperatures to the nearest whole degree.
        self.degreesC = lroundf([(NSNumber *)data[@"current_observation"][@"temp_c"] floatValue]);
        self.degreesF = lroundf([(NSNumber *)data[@"current_observation"][@"temp_f"] floatValue]);
        self.conditionsAsOf = [NSDate date];
        
    }];
    
}

- (void)fetchThreeDayForecast {
}


// find the city and state based on coordinates.
- (void)fetchGeolocation:(WAGeolocationCallback)then {
    
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
        self.fullName     = data[@"location"][@"full"];
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
        
    }];
}

#pragma mark - Current location properties

// NOTE: these getters are disabled because they are synthesized.
// currently, the properties are nonatomic. if for some reason
// it becomes necessary for them to be atomic, enable these getters.

// coordinate property setter allows us to update the coordinate.
- (void)setCoordinate:(CLLocationCoordinate2D)coordinate {
    _coordinate = coordinate;
    [self.viewController updateCoordinate:coordinate];
}

// coordinate getter.
- (CLLocationCoordinate2D)coordinate {
    return _coordinate;
}

#pragma mark - City/region/country properties

- (void)setCity:(NSString *)city {
    if (![city length]) return;
    _city = city;
    [self.viewController updateLocationTitle:self.city];
}

- (void)setState:(NSString *)state {
    if (![state length]) return;
    _state = state;
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

- (void)setFullName:(NSString *)fullName {
    NSLog(@"full name: %@", fullName);
    if (![fullName length]) return;
    _fullName = fullName;
    [self.viewController updateFullTitle:fullName];
}

#pragma mark - Automatic properties

// automatic.

- (NSString *)region {
    return self.state ? self.state : self.country;
}

- (NSString *)regionShort {
    return self.stateShort ? self.stateShort : self.countryShort;
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

#pragma mark - Safe properties

- (NSString *)safeCity {
    return [self.city stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)safeRegion {
    return [self.region stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)safeRegionShort {
    return [self.regionShort stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)lookupRegion {
    if (self.stateShort) return self.stateShort;
    return self.country ? self.country : self.regionShort;
}

@end
