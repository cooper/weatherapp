//
//  WADailyForecastTVC.m
//  Weather
//
//  Created by Mitchell Cooper on 3/22/14.
//  Copyright (c) 2014 Really Good. All rights reserved.
//

#import "WADailyForecastTVC.h"
#import "WALocation.h"
#import "WALocationListTVC.h"
#import "UITableView+Reload.h"

@implementation WADailyForecastTVC

- (id)initWithLocation:(WALocation *)location {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.location = location;
        if (!self.location.fakeLocations)
            self.location.fakeLocations = [NSMutableArray array];
        fakeLocations = self.location.fakeLocations;
    }
    return self;
}
        

#pragma mark - Table view controller

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title     = @"Forecast";
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorInset = UIEdgeInsetsZero;

    // refresh button.
    refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshButtonTapped)];
    self.navigationItem.rightBarButtonItem = refreshButton;

    [self update:NO];
}

#pragma mark - Weather info

- (void)update {
    [self update:YES];
}

- (void)update:(BOOL)animated {

    // generate new cell information.
    forecastedConditions = [self forecastForLocation:self.location];

    // update the background if necessary.
    if (background != self.location.background)
        self.tableView.backgroundView = [[UIImageView alloc] initWithImage:self.location.background];
    background = self.location.background;
    
    // update table.
    [self.tableView reloadData:animated];

    // loading.
    if (self.location.loading) [self showIndicator];
    else [self hideIndicator];
    
}

- (NSArray *)forecastForLocation:(WALocation *)location {
    NSMutableArray *a = [NSMutableArray array];
    for (unsigned int i = 0; i < [self.location.forecast count]; i++)
        [a addObject:[self forecastForDay:self.location.forecast[i] index:i]];
    return a;
}

- (NSArray *)forecastForDay:(NSDictionary *)f index:(unsigned int)i {
    NSMutableArray *a    = [NSMutableArray array];

    // create a fake location for the cell.
    WALocation *location;
    if ([fakeLocations count] >= i + 1)
        location = fakeLocations[i];
    else
        location = fakeLocations[i] = [[WALocation alloc] init];
    
    location.loading     = NO;
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.location.forecast count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [forecastedConditions[section][1] count] + 1; // plus header
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath.row) return 100;
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    // generic base cell.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) cell       = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    cell.backgroundColor  = [UIColor colorWithRed:235./255. green:240./255. blue:1 alpha:0.6];
    cell.detailTextLabel.textColor = [UIColor blackColor];
    
    // artificial location row of a future day.
    if (!indexPath.row) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"location"];
        WALocation *location = forecastedConditions[indexPath.section][0];
        [WALocationListTVC applyWeatherInfo:location toCell:cell];
        return cell;
    }
    
    // detail label on a forecast.
    cell.textLabel.text          = forecastedConditions[indexPath.section][1][indexPath.row - 1][0];
    cell.detailTextLabel.text    = forecastedConditions[indexPath.section][1][indexPath.row - 1][1];
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
    [self.location fetchForecast];

    // loading and refresh button is visible.
    if (self.location.loading) [self showIndicator];
    
}

#pragma mark - Indicators

// show the loading indicators.
- (void)showIndicator {
    if (indicator) return;
    
    // bar button indicator.
    UIActivityIndicatorView *ind = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [ind startAnimating];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:ind];
    [self.navigationItem setRightBarButtonItem:item animated:YES];
    
    // big indicator.
    indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.tableView addSubview:indicator];
    indicator.center = [self.tableView convertPoint:self.tableView.center fromView:self.tableView.superview];
    [indicator startAnimating];

}

// hide the loading indicators.
- (void)hideIndicator {
    if (!indicator) return;
    [self.navigationItem setRightBarButtonItem:refreshButton animated:YES];
    [indicator removeFromSuperview];
    indicator = nil;
}

@end
