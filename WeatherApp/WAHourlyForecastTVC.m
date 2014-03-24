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
#import <QuartzCore/QuartzCore.h>

@implementation WAHourlyForecastTVC

- (id)initWithLocation:(WALocation *)location {
    self = [super initWithStyle:UITableViewStylePlain];
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
    daysAdded = [NSMutableArray array];
    lastDay   = currentDayIndex = -1;
    for (unsigned int i = 0; i < [self.location.hourlyForecast count]; i++)
        [self addForecastForHour:self.location.hourlyForecast[i] index:i];
}

// format is forecasts[day in month][hour index] = dictionary of info for that hour
// then, the array is shifted so the smallest index becomes 0.
- (void)addForecastForHour:(NSDictionary *)f index:(unsigned int)i {

    // create a date from the unix time and a gregorian calendar.
    NSDate *date          = [NSDate dateWithTimeIntervalSince1970:[f[@"FCTTIME"][@"epoch"] integerValue]];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    // if setting says to, switch to location's time zone.
    if (SETTING_IS(kTimeZoneSetting, kTimeZoneRemote))
        [gregorian setTimeZone:self.location.timeZone];
    
    // fetch the information we need.
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
    if ([forecasts count] == 0 || currentDayIndex > [forecasts count] - 1) {
    
        // determine the day name.
        NSDateFormatter *formatter = [NSDateFormatter new];
        if (SETTING_IS(kTimeZoneSetting, kTimeZoneRemote))
            [formatter setTimeZone:self.location.timeZone];
        NSString *dayName, *dateName;

        // determine day of week.
        formatter.dateFormat = @"EEEE";
        dayName = [formatter stringFromDate:date];
        
        // add to list.
        // if it's there already, say "next" weekday,
        // such as "Next Tuesday"
        if ([daysAdded containsObject:dayName])
            dayName = FMT(@"Next %@", dayName);
        else
            [daysAdded addObject:dayName];
        
        // this is today in our local timezone.
        // in other words, the day in the month is equal in both locations,
        // so we will say "Today."
        [gregorian setTimeZone:[NSTimeZone localTimeZone]];
        NSUInteger today = [gregorian components:NSDayCalendarUnit fromDate:[NSDate date]].day;
        if (today == dateComponents.day)
            dayName = @"Today";

        // determine the date string.
        formatter.dateFormat = @"MMMM d";
        dateName = [formatter stringFromDate:date];
        
        // create the day array with the name as the first object.
        [forecasts addObject:[NSMutableArray arrayWithObject:@[dayName, dateName]]];
        
    }
    NSMutableArray *day = forecasts[currentDayIndex];
    
    // information we care about.
    [day addObject:@{
        @"date":            date,
        @"dateComponents":  dateComponents,
        @"icon":            f[@"icon"],
        @"icon_url":        f[@"icon_url"],
        @"temp_c":          f[@"temp"][@"metric"],
        @"temp_f":          f[@"temp"][@"english"],
        @"condition":       f[@"condition"]
    }];
    NSLog(@"just added: %@", [day lastObject]);
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [forecasts count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [forecasts[section] count] - 1; // excluding header
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    UILabel *conditionLabel, *timeLabel;

    // new cell.
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
        
        // create condition label.
        conditionLabel = [[UILabel alloc] initWithFrame:CGRectMake(115, 0, 155, 50)];
        conditionLabel.tag = 17;
        conditionLabel.adjustsFontSizeToFitWidth = YES;
        //conditionLabel.backgroundColor = [UIColor yellowColor];
        [cell.contentView addSubview:conditionLabel];

        // create time label.
        timeLabel      = [[UILabel alloc] initWithFrame:CGRectMake(50, 0, 50, 50)];
        timeLabel.tag  = 16;
        timeLabel.font = [UIFont systemFontOfSize:20];
        timeLabel.textAlignment  = NSTextAlignmentRight;
        //timeLabel.backgroundColor = [UIColor yellowColor];
        [cell.contentView addSubview:timeLabel];
        
        cell.backgroundColor = [UIColor colorWithRed:235./255. green:240./255. blue:1 alpha:0.7];
        cell.detailTextLabel.textColor = [UIColor blackColor];
        
        // shadow on icon.
        cell.imageView.layer.shadowColor     = [UIColor blackColor].CGColor;
        cell.imageView.layer.shadowOffset    = CGSizeMake(0, 0);
        cell.imageView.layer.shadowRadius    = 0.3;
        cell.imageView.layer.shadowOpacity   = 1.0;
        cell.imageView.layer.masksToBounds   = NO;
        cell.imageView.layer.shouldRasterize = YES;
    
        cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:20];
    }
    
    // reusing cell.
    else for (UIView *view in cell.contentView.subviews) {
        if (view.tag == 17) conditionLabel = (UILabel *)view;
        if (view.tag == 16) timeLabel      = (UILabel *)view;
    }
    
    // detail label on a forecast.
    NSDictionary *dict = forecasts[indexPath.section][indexPath.row + 1];
    NSDateComponents *dateComponents = dict[@"dateComponents"];
    NSUInteger hour = dateComponents.hour;
    
    // adjust AM/PM.
    BOOL pm = NO;
    if (hour == 0) hour = 12;
    if (hour >= 12) {
        pm = YES;
        if (hour > 12) hour -= 12;
    }
    
    // create a fake location for the icons and temperatures.
    WALocation *location = [WALocation new];
    location.response = @{
        @"icon":        dict[@"icon"],
        @"icon_url":    dict[@"icon_url"]
    };
    location.degreesC = [dict[@"temp_c"] floatValue];
    location.degreesF = [dict[@"temp_f"] floatValue];
    [location fetchIcon];
    
    // 30x30 icon with a slight shadow to increase visibility.
    cell.imageView.image = [UIImage imageNamed:FMT(@"icons/30/%@", location.conditionsImageName)];

    // time label.
    NSString *time = FMT(@"%ld %@", (long)hour, pm ? @"pm" : @"am");
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:time];
    NSRange range = NSMakeRange([time length] - 2, 2);
    [string addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14] range:range];
    timeLabel.attributedText = string;

    // temperature and condition labels.
    cell.detailTextLabel.text = location.temperature;
    conditionLabel.text = dict[@"condition"];
    
    return cell;
}

// disable selection of cells.
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"day"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"day"];
        cell.backgroundColor            = [UIColor colorWithRed:21./255. green:137./255. blue:1 alpha:0.9];;
        cell.textLabel.textColor        = [UIColor whiteColor];
        cell.detailTextLabel.textColor  = [UIColor whiteColor];
        cell.textLabel.font             = [UIFont boldSystemFontOfSize:22];
    }
    cell.textLabel.text         = forecasts[section][0][0];
    cell.detailTextLabel.text   = forecasts[section][0][1];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
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
