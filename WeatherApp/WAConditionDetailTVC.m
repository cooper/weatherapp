//
//  WAConditionDetailTVC.m
//  Weather
//
//  Created by Mitchell Cooper on 1/22/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

#import "WAConditionDetailTVC.h"
#import "WALocation.h"
#import "WALocationListTVC.h"
#import "WAPageViewController.h"
#import "UITableView+Reload.h"

@implementation WAConditionDetailTVC

- (id)initWithLocation:(WALocation *)location {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) self.location = location;
    return self;
}

#pragma mark - Table view controller

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.titleView = [appDelegate.pageVC menuLabelWithTitle:@"Details"];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorInset = UIEdgeInsetsZero;

    // refresh button.
    refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshButtonTapped)];
    self.navigationItem.rightBarButtonItem = refreshButton;
}

// update if settings have been changed.
- (void)viewWillAppear:(BOOL)animated {
    if (!lastUpdate || [appDelegate.lastSettingsChange timeIntervalSinceDate:lastUpdate] > 0)
        [self update:NO];
}

#pragma mark - Weather info

- (void)update {
    [self update:YES];
}

- (void)update:(BOOL)animated {
    lastUpdate = [NSDate date];
    
    // generate new cell information.
    currentConditions    = [self detailsForLocation:self.location];
    
    // update table.
    [self.tableView reloadData:animated];
    
    // update the background if necessary.
    if (background != self.location.background)
        self.tableView.backgroundView = [[UIImageView alloc] initWithImage:self.location.background];
    background = self.location.background;
    
    // loading and refresh button is visible.
    if (self.location.loading && self.navigationItem.rightBarButtonItem == refreshButton) {
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [indicator startAnimating];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:indicator];
        [self.navigationItem setRightBarButtonItem:item animated:YES];
    }
    
    // not loading and refresh button is not visible.
    else if (!self.location.loading && self.navigationItem.rightBarButtonItem != refreshButton)
        [self.navigationItem setRightBarButtonItem:refreshButton animated:YES];
    
}

- (NSArray *)detailsForLocation:(WALocation *)location {
    NSMutableArray *final = [NSMutableArray array];
    NSDictionary   *r     = location.response;
    
    // local time formatter.
    NSDateFormatter *fmt = [NSDateFormatter new];
    fmt.dateFormat = @"h:mm a";
    
    // remote time formatter.
    NSDateFormatter *rfmt = [NSDateFormatter new];
    rfmt.timeZone   = self.location.timeZone;
    rfmt.dateFormat = @"h:mm a";
    
    // initial values of "NA"
    NSString *dewPoint, *heatIndex, *windchill, *pressure, *visibility, *precipT,
        *precipH, *windSpeed, *windDirection, *gustSpeed, *uv;
    dewPoint  = heatIndex = windchill     = pressure  = visibility = precipT = uv =
    precipH   = windSpeed = windDirection = gustSpeed = @"NA";
    
    // dewpoint.
    if (location.dewPointC != TEMP_NONE)
        dewPoint = FMT(@"%@%@", [location dewPoint:1], location.tempUnit);
    
    // heat index.
    if (location.heatIndexC != TEMP_NONE && ![self.location.temperature isEqualToString:self.location.heatIndex])
        heatIndex = FMT(@"%@%@", [location heatIndex:1], location.tempUnit);
    
    // windchill.
    if (location.windchillC != TEMP_NONE && ![self.location.temperature isEqualToString:self.location.windchill])
        windchill = FMT(@"%@%@", [location windchill:1], location.tempUnit);
    
    // precipitation.
    if ([r[@"precip_today_metric"] floatValue] > 0) {
    
        // in inches.
        if (SETTING_IS(kPrecipitationMeasureSetting, kPrecipitationMeasureInches)) {
            precipT = FMT(@"%@ in", r[@"precip_today_in"]);
            precipH = FMT(@"%@ in", r[@"precip_1hr_in"]);
        }
        
        // in millimeters.
        else {
            precipT = FMT(@"%@ in", r[@"precip_today_metric"]);
            precipH = FMT(@"%@ in", r[@"precip_1hr_metric"]);
        }
        
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
        @"Temperature",         FMT(@"%@%@", [location temperature:1], location.tempUnit),
        @"Feels like",          FMT(@"%@%@", [location feelsLike:1],   location.tempUnit),
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
        @"Time at location",    FMT(@"%@ %@", [rfmt stringFromDate:[NSDate date]], self.location.timeZone.abbreviation),
        @"Last observation",    [fmt stringFromDate:self.location.observationsAsOf],
        @"Last fetch",          [fmt stringFromDate:self.location.conditionsAsOf],
        @"Latitude",            FMT(@"%f", self.location.latitude),
        @"Longitude",           FMT(@"%f", self.location.longitude)
    ];
    
    // filter out the "NA" values.
    for (NSUInteger i = 0; i < [details count]; i += 2) {
        if ([details[i + 1] isEqual:@"NA"]) continue;
        [final addObject:@[ details[i], details[i + 1] ]];
    }
    
    return final;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [currentConditions count] + 2; // plus header and maps
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath.row) return 100;
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;

    // show the location cell for this location.
    if (!indexPath.row) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
        [WALocationListTVC applyWeatherInfo:self.location toCell:cell];
        cell.backgroundView = nil;
        return cell;
    }
    
    // open in maps.
    if (indexPath.row == [currentConditions count] + 1) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
        cell.selectedBackgroundView = [UIView new];
        cell.selectedBackgroundView.backgroundColor = [UIColor colorWithRed:0 green:150./255. blue:1 alpha:0.3];
        cell.textLabel.text       = FMT(@"Open %@ in Maps", self.location.city);
        cell.detailTextLabel.text = @"🌎";
    }
    
    // detail cell.
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"detail"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"detail"];
            //cell.textLabel.textColor = [UIColor colorWithRed:0  green:70./255. blue:200./255. alpha:1];
            cell.textLabel.font      = [UIFont boldSystemFontOfSize:cell.textLabel.font.pointSize];
        }
        
        // detail for current conditions.
        cell.textLabel.text       = currentConditions[indexPath.row - 1][0];
        cell.detailTextLabel.text = currentConditions[indexPath.row - 1][1];
    }

    // for all non-location cells.
    cell.backgroundColor = [UIColor colorWithRed:235./255. green:240./255. blue:1 alpha:0.6];
    cell.detailTextLabel.textColor = DARK_BLUE_COLOR;
    
    return cell;
}

// disable selection of cells.
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == [currentConditions count] + 1) return YES;
    return NO;
}

// selected "open in maps"
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row != [currentConditions count] + 1) return;
    NSURL *url = [NSURL URLWithString:FMT(@"http://maps.apple.com/?q=%f,%f", self.location.latitude, self.location.longitude)];
    [[UIApplication sharedApplication] openURL:url];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Interface actions

- (void)refreshButtonTapped {

    // fetch most recent data.
    [self.location fetchCurrentConditions];

    // loading and refresh button is visible.
    if (self.location.loading && self.navigationItem.rightBarButtonItem == refreshButton) {
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [indicator startAnimating];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:indicator];
        [self.navigationItem setRightBarButtonItem:item animated:YES];
    }
    
}


@end
