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

- (id)initWithBackground:(UIImage *)bg location:(WALocation *)location {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.location = location;
        background    = bg;
    }
    return self;
}
        

#pragma mark - Table view controller

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title     = @"Details";
    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:background];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorInset = UIEdgeInsetsZero;

    currentConditions    = [self detailsForLocation:self.location];
    forecastedConditions = [self forecastForLocation:self.location];
}

#pragma mark - Weather info

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
        
        // wind in miles.
        if ([r[@"wind_mph"] floatValue] > 0) [a addObjectsFromArray:@[
            @[@"Wind speed",        FMT(@"%@ mph",      r[@"wind_mph"])                     ],
            @[@"Gust speed",        FMT(@"%@ mph",      r[@"wind_gust_mph"])                ],
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
    for (NSUInteger i = 0; i < [location.forecast count]; i ++)
        [a addObject:[self forecastForDay:location.forecast[i] text:location.textForecast[i]]];
    return a;
}

- (NSArray *)forecastForDay:(NSDictionary *)f text:(NSDictionary *)t {
    NSMutableArray *a    = [NSMutableArray array];

    // create a fake location for the cell.
    WALocation *location = [[WALocation alloc] init];
    location.loading     = NO;
    location.initialLoadingComplete = YES;
    
    // temperatures.
    location.degreesC   = [f[@"high"][@"celsius"]    floatValue];
    location.degreesF   = [f[@"high"][@"fahrenheit"] floatValue];
    location.feelsLikeC = [f[@"low"][@"celsius"]     floatValue];
    location.feelsLikeF = [f[@"low"][@"fahrenheit"]  floatValue];
    
    // location (time).
    location.city       = f[@"date"][@"weekday"];
    location.region     = FMT(@"%@ %@", f[@"date"][@"monthname_short"], f[@"date"][@"day"]);
    
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
    
    // other detail cells.
    [a addObjectsFromArray:@[
        @[@"High temperature", FMT(@"%@ %@", location.temperature, location.tempUnit)       ],
        @[@"Low temperature",  FMT(@"%@ %@", location.feelsLike,   location.tempUnit)       ],
        @[@"Avg. humidity",    FMT(@"%@%%", f[@"avehumidity"])                              ],
        @[@"Min. humidity",    FMT(@"%@%%", f[@"minhumidity"])                              ],
        @[@"Max. humidity",    FMT(@"%@%%", f[@"maxhumidity"])                              ]
    ]];
    
    // wind info and visibility in miles.
    if (SETTING_IS(kDistanceMeasureSetting, kDistanceMeasureMiles)) [a addObjectsFromArray:@[
        @[@"Wind speed",        FMT(@"%@ mph",      f[@"avewind"][@"mph"])                  ],
        @[@"Gust speed",        FMT(@"%@ mph",      f[@"maxwind"][@"mph"])                  ],
        @[@"Wind direction",    FMT(@"%@ %@º",      f[@"avewind"][@"dir"], f[@"avewind"][@"degrees"])   ],
    ]];
    
    // wind info and visibility in kilometers.
    else [a addObjectsFromArray:@[
        @[@"Wind speed",        FMT(@"%@ km/hr",    f[@"avewind"][@"kph"])                  ],
        @[@"Gust speed",        FMT(@"%@ km/hr",    f[@"maxwind"][@"kph"])                  ],
        @[@"Wind direction",    FMT(@"%@ %@º",      f[@"avewind"][@"dir"], f[@"avewind"][@"degrees"])   ],
    ]];
    
    
    
    // forecast description.
    // FIXME: this is completely wrong.
    //if (SETTING_IS(kTemperatureScaleSetting, kTemperatureScaleFahrenheit))
    //    [a addObject:@[FMT(@"%@\n%@", t[@"title"], t[@"fcttext"]), @""]];
    //else
    //    [a addObject:@[FMT(@"%@\n%@", t[@"title"], t[@"fcttext_metric"]), @""]];
    //
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

@end
