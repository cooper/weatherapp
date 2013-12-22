//
//  WALocation.m
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/28/13.
//  Copyright (c) 2013 Really Good. All rights reserved.
//

#import "WALocation.h"
#import "WAWeatherVC.h"
#import "WALocationManager.h"
#import "WANavigationController.h"
#import "WALocationListTVC.h"
#import "WAPageViewController.h"

@implementation WALocation

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
    // todo: err handling, call endLoading in err.
    [self beginLoading];
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
            NSString *icon = ob[@"icon"];
            
            // alternate names for icons.
            if ([icon isEqualToString:@"hazy"])         icon = @"fog";
            if ([icon isEqualToString:@"partlysunny"])  icon = @"partlycloudy";
            
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
        
        // update as of time, and finish loading process.
        self.conditionsAsOf   = [NSDate date];
        self.observationsAsOf = [NSDate dateWithTimeIntervalSince1970:[ob[@"observation_epoch"] doubleValue]];
        self.observationTimeString = [ob[@"observation_time"] stringByReplacingOccurrencesOfString:@"Last Updated on " withString:@""];
        
        [self endLoading];
        
        // execute callback.
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
        @"degreesC",            @"degreesF"
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
        NSLog(@"icon and conditions not changed");
    
    // find a background.
    else for (NSDictionary *bg in backgrounds) {
        BOOL matchesIcon = bg[@"icon"] && [self.conditionsImageName rangeOfString:bg[@"icon"] options:NSCaseInsensitiveSearch].location != NSNotFound;
        BOOL matchesConditions = bg[@"conditions"] && [self.conditions rangeOfString:bg[@"conditions"] options:NSCaseInsensitiveSearch].location != NSNotFound;
        
        // this is a match.
        if (matchesIcon || matchesConditions) {
            
            NSLog(@"%@ matches!", bg[@"name"]);
            
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
        NSLog(@"conditions/icon changed, but category and time of day still same");
    
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
        
        NSLog(@"chosen: %@", chosenBackground);
        
    }
    
    // finally apply the background.
    if (chosenBackground) {
        self.currentBackgroundName       = selection[@"name"];
        self.currentBackgroundIcon       = self.conditionsImageName;
        self.currentBackgroundConditions = self.conditions;
        self.currentBackgroundTimeOfDay  = [selection[@"night"] boolValue];
        self.background     = [self preloadImage:[UIImage imageNamed:FMT(@"backgrounds/%@.jpg", chosenBackground)]];
        self.cellBackground = [self preloadImage:[UIImage imageNamed:FMT(@"backgrounds/100/%@.jpg", chosenBackground)]];
    }
    
}

// preload image.
// FIXME: from https://gist.github.com/steipete/1144242
// - needs paraphrasing and cleanup.
- (UIImage *)preloadImage:(UIImage *)uiimage {
    CGImageRef image = uiimage.CGImage;
    
    // make a bitmap context of a suitable size to draw to, forcing decode
    size_t width  = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    
    CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef imageContext   =  CGBitmapContextCreate(
                                                         NULL, width, height, 8, width * 4, colourSpace,
                                                         kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little
                                                         );
    CGColorSpaceRelease(colourSpace);
    
    // draw the image to the context, release it
    CGContextDrawImage(imageContext, CGRectMake(0, 0, width, height), image);
    
    // now get an image ref from the context
    CGImageRef outputImage = CGBitmapContextCreateImage(imageContext);
    
    UIImage *cachedImage = [UIImage imageWithCGImage:outputImage];
    
    // clean up
    CGImageRelease(outputImage);
    CGContextRelease(imageContext);
    
    return cachedImage;
}

@end
