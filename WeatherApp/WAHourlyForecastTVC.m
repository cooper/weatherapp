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
    if (self) self.location = location;
    return self;
}
        

#pragma mark - Table view controller

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // forecast not yet obtained.
    if (!self.location.hourlyForecastResponse)
        [self.location fetchHourlyForecast:NO];
    
    self.navigationItem.titleView = [appDelegate.pageVC menuLabelWithTitle:@"Hourly forecast"];
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
    [self.location updateHourlyForecast];
    
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSUInteger count = [self.location.hourlyForecast count];
    return count > 5 ? count : count + 1; // 1 extra for more button
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == [self.location.hourlyForecast count]) return 1;
    return [self.location.hourlyForecast[section] count] - 1; // excluding header
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    // more button.
    if (indexPath.section == [self.location.hourlyForecast count]) {
        UITableViewCell *cell       = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
        cell.textLabel.text         = @"See further into the future";
        cell.detailTextLabel.text   = @"🕝";
        cell.backgroundColor        = [UIColor colorWithRed:235./255. green:240./255. blue:1 alpha:0.7];
        cell.selectedBackgroundView = [UIView new];
        cell.selectedBackgroundView.backgroundColor = [UIColor colorWithRed:0 green:150./255. blue:1 alpha:0.3];
        return cell;
    }

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    UILabel *conditionLabel, *timeLabel;

    // new cell.
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
        
        // create condition label.
        conditionLabel     = [[UILabel alloc] initWithFrame:CGRectMake(115, 0, 155, 50)];
        conditionLabel.tag = 17;
        conditionLabel.adjustsFontSizeToFitWidth = YES;
        [cell.contentView addSubview:conditionLabel];

        // create time label.
        timeLabel       = [[UILabel alloc] initWithFrame:CGRectMake(50, 0, 50, 50)];
        timeLabel.tag   = 16;
        timeLabel.font  = [UIFont systemFontOfSize:20];
        timeLabel.textAlignment = NSTextAlignmentRight;
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
    else {
        timeLabel      = (UILabel *)[cell.contentView viewWithTag:16];
        conditionLabel = (UILabel *)[cell.contentView viewWithTag:17];
    }
    
    // detail label on a forecast.
    NSDictionary *dict = self.location.hourlyForecast[indexPath.section][indexPath.row + 1];
    
    // 30x30 icon with a slight shadow to increase visibility.
    cell.imageView.image = dict[@"iconImage"];

    // labels.
    timeLabel.attributedText  = dict[@"prettyHour"];
    cell.detailTextLabel.text = dict[@"temperature"];
    conditionLabel.text       = dict[@"condition"];
    
    return cell;
}

// disable selection of cells except for more button.
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == [self.location.hourlyForecast count]) return YES;
    return NO;
}

// more button selected.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section != [self.location.hourlyForecast count]) return;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.location fetchHourlyForecast:YES];
    tenDay = YES; // remember for refresh
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == [self.location.hourlyForecast count]) return nil;

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"day"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"day"];
        cell.backgroundColor            = [UIColor colorWithRed:21./255. green:137./255. blue:1 alpha:0.9];;
        cell.textLabel.textColor        = [UIColor whiteColor];
        cell.detailTextLabel.textColor  = [UIColor whiteColor];
        cell.textLabel.font             = [UIFont boldSystemFontOfSize:22];
    }
    cell.textLabel.text         = self.location.hourlyForecast[section][0][0];
    cell.detailTextLabel.text   = self.location.hourlyForecast[section][0][1];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == [self.location.hourlyForecast count]) return 0;
    return 40;
}

#pragma mark - Interface actions

- (void)refreshButtonTapped {

    // fetch most recent data.
    [self.location fetchHourlyForecast:tenDay];

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
