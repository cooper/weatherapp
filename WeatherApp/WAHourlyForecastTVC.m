//
//  WADailyForecastTVC.m
//  Weather
//
//  Created by Mitchell Cooper on 3/22/14.
//  Copyright (c) 2014 Really Good. All rights reserved.
//

#import "WAHourlyForecastTVC.h"
#import "WALocation.h"
#import "WALocationListTVC.h"
#import "UITableView+Reload.h"
#import "WAPageViewController.h"

@implementation WAHourlyForecastTVC

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
    
    // forecast not yet obtained.
    if (!self.location.hourlyForecast)
        [self.location fetchHourlyForecast];
    
    self.navigationItem.titleView = [appDelegate.pageVC menuLabelWithTitle:@"Hourly forecast"];
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
    [self updateForecasts];
    
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

- (void)updateForecasts {
    forecasts = [NSMutableArray array];
    lastDay   = currentDayIndex = -1;
    for (unsigned int i = 0; i < [self.location.hourlyForecast count]; i++)
        [self addForecastForHour:self.location.hourlyForecast[i] index:i];
}

// format is forecasts[day in month][hour index] = dictionary of info for that hour
// then, the array is shifted so the smallest index becomes 0.
- (void)addForecastForHour:(NSDictionary *)f index:(unsigned int)i {

    // determine the date components in the gregorian calendar.
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[f[@"FCTTIME"][@"epoch"] integerValue]];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *dateComponents = [gregorian components:NSDayCalendarUnit | NSHourCalendarUnit fromDate:date];
    
    // adjust the day index to the offset.
    NSUInteger dayIndex = dateComponents.day;
    
    // the day has changed.
    if (dayIndex != lastDay) {
        currentDayIndex++;
        lastDay = dayIndex;
        NSLog(@"day changed; new current(%lu), lastDay(%lu)", (unsigned long)currentDayIndex, (unsigned long)lastDay);
    }
    
    // this day does not yet exist.
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat       = @"EEEE";
    NSString *dayName          = [formatter stringFromDate:date];
    if ([forecasts count] == 0 || currentDayIndex > [forecasts count] - 1)
        [forecasts addObject:[NSMutableArray arrayWithObject:dayName]];
    NSMutableArray *day = forecasts[currentDayIndex];
    
    // information we care about.
    [day addObject:@{
        @"date":            date,
        @"dateComponents":  dateComponents,
        @"icon":            f[@"icon"],
        @"icon_url":        f[@"icon_url"],
        @"temp_c":          f[@"temp"][@"metric"],
        @"temp_f":          f[@"temp"][@"english"]
    }];
    NSLog(@"just added: %@", [day lastObject]);
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [forecasts count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [forecasts[section] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    // generic base cell.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) cell       = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    cell.backgroundColor  = [UIColor colorWithRed:235./255. green:240./255. blue:1 alpha:0.6];
    cell.detailTextLabel.textColor = [UIColor blackColor];
    
    // artificial location row of a day.
    if (!indexPath.row) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"day"];
        cell.backgroundColor = [UIColor colorWithRed:  0./255. green:150./255. blue:1 alpha:0.5];
        cell.textLabel.text = forecasts[indexPath.section][0];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:22];
        cell.textLabel.textColor = [UIColor whiteColor];
        return cell;
    }
    
    // detail label on a forecast.
    NSDictionary *dict = forecasts[indexPath.section][indexPath.row];
    NSDateComponents *dateComponents = dict[@"dateComponents"];
    NSUInteger hour      = dateComponents.hour;
    if (hour == 0) hour  = 12;
    if (hour > 12) hour -= 12;
    
    cell.textLabel.text          = FMT(@"%ld", (long)hour);
    cell.detailTextLabel.text    = FMT(@"%@", dict[@"temp_f"]);
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
    [self.location fetchHourlyForecast];

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
