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
    self = [super initWithStyle:UITableViewStyleGrouped];
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

    [self update:YES];
}

#pragma mark - Weather info

- (void)update {
    [self update:NO];
}

- (void)update:(BOOL)firstTime {

    // generate new cell information.
    currentConditions    = [self detailsForLocation:self.location];
    
    // update table.
    [self.tableView reloadData:!firstTime];
    
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
    
    // time formatter.
    NSDateFormatter *fmt = [NSDateFormatter new];
    [fmt setTimeZone:[NSTimeZone localTimeZone]];
    [fmt setDateFormat:@"h:mm a"];
    
    // initial values of "NA"
    NSString *dewPoint, *heatIndex, *windchill, *pressure, *visibility, *percipT,
        *percipH, *windSpeed, *windDirection, *gustSpeed, *gustDirection;
    dewPoint  = heatIndex = windchill     = pressure  = visibility    = percipT =
    percipH   = windSpeed = windDirection = gustSpeed = gustDirection = @"NA";
    
    // dewpoint.
    if (location.dewPointC != TEMP_NONE)
        dewPoint = FMT(@"%@ %@", location.dewPoint, location.tempUnit);
    
    // heat index.
    if (location.heatIndexC != TEMP_NONE)
        heatIndex = FMT(@"%@ %@", location.heatIndex, location.tempUnit);
    
    // windchill.
    if (location.windchillC != TEMP_NONE)
        windchill = FMT(@"%@ %@", location.windchill, location.tempUnit);
    
    
    // percipitation.
    if ([r[@"percip_today_metric"] floatValue] > 0) {
    
        // in inches.
        if (SETTING_IS(kPercipitationMeasureSetting, kPercipitationMeasureInches)) {
            percipT = FMT(@"%@ in", r[@"precip_today_in"]);
            percipH = FMT(@"%@ in", r[@"precip_1hr_in"]);
        }
        
        // in millimeters.
        else {
            percipT = FMT(@"%@ in", r[@"precip_today_metric"]);
            percipH = FMT(@"%@ in", r[@"precip_1hr_metric"]);
        }
        
    }
    
    // pressure.
    pressure = SETTING_IS(kPressureMeasureSetting, kPressureMeasureInchHg) ?
        FMT(@"%@ inHg", r[@"pressure_in"])                                 :
        FMT(@"%@ inHg", r[@"pressure_mb"]);

    // miles.
    if (SETTING_IS(kDistanceMeasureSetting, kDistanceMeasureMiles)) {
        
        // wind in miles.   (using floatValue forces minimum number of decimals)
        if ([r[@"wind_mph"] floatValue] > 0) {
            windSpeed     = FMT(@"%@ mph", @( [r[@"wind_mph"] floatValue] ));
            windDirection = FMT(@"%@ %@º", r[@"wind_dir"], r[@"wind_degrees"]);
        }
        
        // gusts in miles.
        if ([r[@"wind_gust_mph"] floatValue] > 0) {
            gustSpeed     = FMT(@"%@ mph", @( [r[@"wind_gust_mph"] floatValue] ));
            gustDirection = FMT(@"%@ %@º", r[@"wind_gust_dir"], r[@"wind_gust_degrees"]);
        }
        
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
        if ([r[@"wind_gust_kph"] floatValue] > 0) {
            gustSpeed = FMT(@"%@ km/hr", @( [r[@"wind_gust_kph"] floatValue] ));
            gustDirection = FMT(@"%@ %@º", r[@"wind_gust_dir"], r[@"wind_gust_degrees"]);
        }
        
        // visibility in km.
        if ([r[@"visibility_km"] floatValue] > 0)
            visibility = FMT(@"%@ km", r[@"visibility_km"]);
        
    }
    
    NSArray *details = @[
        @"Temperature",         FMT(@"%@ %@", location.temperature, location.tempUnit),
        @"Feels like",          FMT(@"%@ %@", location.feelsLike,   location.tempUnit),
        @"Dew point",           dewPoint,
        @"Heat index",          heatIndex,
        @"Windchill",           windchill,
        @"Pressure",            pressure,
        @"Humidity",            r[@"relative_humidity"],
        @"Visibility",          visibility,
        @"Percip. today",       percipT,
        @"Percip. in hour",     percipH,
        @"Wind speed",          windSpeed,
        @"Wind direction",      windDirection,
        @"Gust speed",          gustSpeed,
        @"Gust direction",      gustDirection,
        @"Last observation",    [fmt stringFromDate:self.location.observationsAsOf],
        @"Last fetch",          [fmt stringFromDate:self.location.conditionsAsOf],
        @"Latitude",            FMT(@"%f", self.location.latitude),
        @"Longitude",           FMT(@"%f", self.location.longitude)
    ];
    
    // add all of them that are not NA.
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
        cell.textLabel.text  = FMT(@"Open %@ in Maps", self.location.city);
        cell.detailTextLabel.text = @"🌎";
    }
    
    // detail cell.
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"detail"];
        if (!cell)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"detail"];
        
        // detail for current conditions.
        cell.textLabel.text       = currentConditions[indexPath.row - 1][0];
        cell.detailTextLabel.text = currentConditions[indexPath.row - 1][1];
    
    }
    
    cell.backgroundColor = [UIColor colorWithRed:235./255. green:240./255. blue:1 alpha:0.6];
    cell.textLabel.textColor       =
    cell.detailTextLabel.textColor = [UIColor blackColor];
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
