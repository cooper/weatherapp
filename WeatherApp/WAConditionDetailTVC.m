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

@implementation WAConditionDetailTVC

- (id)initWithLocation:(WALocation *)location {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) self.location = location;
    return self;
}
        

#pragma mark - Table view controller

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title     = @"Details";
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorInset = UIEdgeInsetsZero;

    // refresh button.
    refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshButtonTapped)];
    self.navigationItem.rightBarButtonItem = refreshButton;

    [self update];
}

#pragma mark - Weather info

- (void)update {

    // generate new cell information.
    currentConditions    = [self detailsForLocation:self.location];
    forecastedConditions = [self forecastForLocation:self.location];
    
    // update table.
    [self.tableView reloadData];
    
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
    NSMutableArray *a = [NSMutableArray array];
    NSDictionary   *r = location.response;
    
    // temperatures.
    [a addObjectsFromArray:@[
        @[@"Temperature",       FMT(@"%@ %@", location.temperature, location.tempUnit)      ],
        @[@"Feels like",        FMT(@"%@ %@", location.feelsLike,   location.tempUnit)      ],
        @[@"Dew point",         FMT(@"%@ %@", location.dewPoint,    location.tempUnit)      ]
    ]];
    
    // only show heat index and wind chill if there is one.
    if (location.heatIndexC != TEMP_NONE) [a addObject:
        @[@"Heat index",        FMT(@"%@ %@", location.heatIndex, location.tempUnit)        ]
    ];
    if (location.windchillC != TEMP_NONE) [a addObject:
        @[@"Windchill",        FMT(@"%@ %@", location.windchill, location.tempUnit)         ]
    ];
    
    // precipitation in inches.
    if (SETTING_IS(kPercipitationMeasureSetting, kPercipitationMeasureInches) &&
        [r[@"percip_today_in"] floatValue] > 0) [a addObjectsFromArray:@[
        @[@"Precip. today",     FMT(@"%@ in",       r[@"precip_today_in"])                  ],
        @[@"Precip. in hour",   FMT(@"%@ in",       r[@"precip_1hr_in"])                    ]
    ]];
    
    // precipitation in milimeters.
    else if ([r[@"percip_today_metric"] floatValue] > 0) [a addObjectsFromArray:@[
        @[@"Precip. today",     FMT(@"%@ mm",       r[@"precip_today_metric"])              ],
        @[@"Precip. in hour",   FMT(@"%@ mm",       r[@"precip_1hr_metric"])                ]
    ]];
    
    // pressure and humidity.
    // (pressure in both milibars and inches regardless of settings)
    [a addObjectsFromArray:@[
        @[@"Pressure",          FMT(@"%@ mb / %@ in", r[@"pressure_mb"], r[@"pressure_in"]) ],
        @[@"Humidity",          r[@"relative_humidity"]                                     ]
    ]];
    
    // miles.
    if (SETTING_IS(kDistanceMeasureSetting, kDistanceMeasureMiles)) {
        
        // wind in miles.   (using floatValue forces minimum number of decimals)
        if ([r[@"wind_mph"] floatValue] > 0) [a addObjectsFromArray:@[
            @[@"Wind speed",        FMT(@"%@ mph",      @([r[@"wind_mph"] floatValue]))     ],
            @[@"Gust speed",        FMT(@"%@ mph",      @([r[@"wind_gust_mph"] floatValue]))],
            @[@"Wind direction",    FMT(@"%@ %@º",      r[@"wind_dir"], r[@"wind_degrees"]) ],
        ]];
        
        // visibility in miles.
        if ([r[@"visibility_mi"] floatValue] > 0) [a addObject:
            @[@"Visibility",        FMT(@"%@ mi",       r[@"visibility_mi"])    ]
        ];
        
    }
    
    // kilometers.
    else {

        // wind in kilometers.
        if ([r[@"wind_kph"] floatValue] > 0) [a addObjectsFromArray:@[
            @[@"Wind speed",        FMT(@"%@ km/hr",    r[@"wind_kph"])                         ],
            @[@"Gust speed",        FMT(@"%@ km/hr",    r[@"wind_gust_kph"])                    ],
            @[@"Wind direction",    FMT(@"%@ %@º",      r[@"wind_dir"], r[@"wind_degrees"])     ],
        ]];
        
        // visibility in kilometers.
        if ([r[@"visibility_km"] floatValue] > 0) [a addObject:
            @[@"Visibility",        FMT(@"%@ km",       r[@"visibility_km"])    ]
        ];
        
    }
    
    // coordinates.
    [a addObjectsFromArray:@[
        @[@"Latitude",          FMT(@"%f", self.location.latitude)  ],
        @[@"Longitude",         FMT(@"%f", self.location.longitude) ]
    ]];
    
    return a;
}

- (NSArray *)forecastForLocation:(WALocation *)location {
    NSMutableArray *a = [NSMutableArray array];
    
    // what is the date?
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *dateComponents = [gregorian components:NSDayCalendarUnit fromDate:[NSDate date]];
    NSNumber *today = @(dateComponents.hour);
    
    // add each day that is not today.
    for (NSDictionary *day in self.location.forecast)
        if (![day[@"date"][@"day"] isEqualToNumber:today])
        [a addObject:[self forecastForDay:day]];
    
    return a;
}

- (NSArray *)forecastForDay:(NSDictionary *)f {
    NSMutableArray *a    = [NSMutableArray array];

    // create a fake location for the cell.
    WALocation *location = [[WALocation alloc] init];
    location.loading     = NO;
    location.initialLoadingComplete = YES;
    
    // temperatures.
    location.degreesC = [f[@"low"][@"celsius"]      floatValue];
    location.degreesF = [f[@"low"][@"fahrenheit"]   floatValue];
    location.highC    = [f[@"high"][@"celsius"]     floatValue];
    location.highF    = [f[@"high"][@"fahrenheit"]  floatValue];
    
    // location (time).
    location.city     = f[@"date"][@"weekday"];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    // number of forecasts + the current conditions.
    return [self.location.forecast count] + 1;
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    // current conditions section.
    if (!section) return [currentConditions count] + 1; // plus header
    
    // forecast section.
    return [forecastedConditions[section - 1][1] count] + 1; // plus header
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    //if (!indexPath.row && !indexPath.section) return 150;
    if (!indexPath.row) return 100;
    
    // description cell.
    //if (indexPath.section && indexPath.row > [forecastedConditions[indexPath.section - 1] count])
    //    return 150;
    
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    // generic base cell.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) cell       = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    cell.backgroundColor  = [UIColor colorWithRed:235./255. green:240./255. blue:1 alpha:0.6];//[UIColor clearColor];
    //cell.textLabel.textColor       = [UIColor whiteColor];
    cell.detailTextLabel.textColor = [UIColor blackColor];//[UIColor whiteColor];
    //cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"navbar.png"]];
    
    // current conditions.
    if (!indexPath.section) {
    
        // show the location cell for this location.
        if (!indexPath.row) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"location"];
            [WALocationListTVC applyWeatherInfo:self.location toCell:cell];
            cell.backgroundView = nil;
            return cell;
        }
    
        // detail for current conditions.
        cell.textLabel.text = currentConditions[indexPath.row - 1][0];
        cell.detailTextLabel.text = currentConditions[indexPath.row - 1][1];
        return cell;
        
    }
    
    // artificial location row of a future day.
    if (!indexPath.row) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"location"];
        WALocation *location = forecastedConditions[indexPath.section - 1][0];
        [WALocationListTVC applyWeatherInfo:location toCell:cell];
        return cell;
    }
    
    // detail label on a forecast.
    cell.textLabel.text          = forecastedConditions[indexPath.section - 1][1][indexPath.row - 1][0];
    cell.detailTextLabel.text    = forecastedConditions[indexPath.section - 1][1][indexPath.row - 1][1];
    cell.textLabel.numberOfLines = 0;
    
    return cell;
}

// disable selection of cells.
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark - Interface actions

- (void)refreshButtonTapped {

    // fetch most recent data.
    [self.location fetchCurrentConditions];
    [self.location fetchForecast];

    // loading and refresh button is visible.
    if (self.location.loading && self.navigationItem.rightBarButtonItem == refreshButton) {
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [indicator startAnimating];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:indicator];
        [self.navigationItem setRightBarButtonItem:item animated:YES];
    }
    
}


@end
