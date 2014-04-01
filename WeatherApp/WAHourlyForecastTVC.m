//
//  WADailyForecastTVC.m
//  Weather
//
//  Created by Mitchell Cooper on 3/22/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

#import "WAHourlyForecastTVC.h"
#import "WALocation.h"
#import "WALocationListTVC.h"
#import "UITableView+Reload.h"
#import "WAPageViewController.h"

@implementation WAHourlyForecastTVC

// initialize with a location.
- (instancetype)initWithLocation:(WALocation *)location {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) self.location = location;
    return self;
}
        

#pragma mark - Table view controller

- (void)viewDidLoad {
    [super viewDidLoad];

    // forecast not yet obtained.
    if (!self.location.hourlyForecastResponse) {
        [self.location fetchHourlyForecast:NO];
        [self.location commitRequest];
    }
    
    self.navigationItem.titleView = [appDelegate.pageViewController menuLabelWithTitle:@"Hourly forecast"];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorInset = UIEdgeInsetsZero;

    // refresh button.
    refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshButtonTapped)];
    self.navigationItem.rightBarButtonItem = refreshButton;

    // register for table headers.
    [self.tableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:@"day"];
    
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

// update anything that has changed.
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
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"more"];
        UIActivityIndicatorView *ind;
        UIImageView *icon;

        // reuse cell.
        if (cell) {
            icon = (UIImageView *)             [cell.contentView viewWithTag:1];
            ind  = (UIActivityIndicatorView *) [cell.contentView viewWithTag:2];
        }
        
        // create cell.
        else {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"more"];
            
            // bold label.
            cell.textLabel.text         = @"See further into the future";
            cell.textLabel.font         = [UIFont boldSystemFontOfSize:cell.textLabel.font.pointSize];
            cell.textLabel.textColor    = [UIColor whiteColor];
            
            // white tint when select.
            cell.backgroundColor        = BLUE_COLOR;
            cell.selectedBackgroundView = [UIView new];
            cell.selectedBackgroundView.backgroundColor = L_CELL_SEL_COLOR;
            
            // hourly menu icon.
            icon       = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icons/menu/hourly"]];
            icon.frame = CGRectMake(cell.contentView.bounds.size.width - 40, 10, 30, 30);
            icon.tag   = 1;
            [cell.contentView addSubview:icon];
            
            // indicator.
            ind     = [[UIActivityIndicatorView alloc] initWithFrame:icon.frame];
            ind.tag = 2;
            [cell.contentView addSubview:ind];
            
        }
        
        // if location is loading, show indicator.
        if (self.location.loading) {
            icon.hidden = YES;
            ind.hidden  = NO;
            [ind startAnimating];
        }
        
        // not loading.
        else {
            [ind stopAnimating];
            ind.hidden  = YES;
            icon.hidden = NO;
        }
        
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
        
        cell.backgroundColor = TABLE_COLOR_T;
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
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    // fetch the forecast.
    tenDay = YES; // remember for refresh
    [self.location fetchHourlyForecast:YES];
    [self.location commitRequestThen:^(NSURLResponse *res, NSDictionary *data) {
        if (self.view.window) [self hideIndicator];
    }];

    // call this to show indicator on the cell.
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    
    // show other loading indicators.
    [self showIndicator];
    
}

// header views. these are reused.
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == [self.location.hourlyForecast count]) return nil;
    UITableViewHeaderFooterView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"day"];
    
    // fetch labels with tags.
    UILabel *dayNameLabel  = (UILabel *)[view.contentView viewWithTag:1];
    UILabel *dateNameLabel = (UILabel *)[view.contentView viewWithTag:2];
    
    // if there is no label, view hasn't been set up.
    if (!dayNameLabel) {
    
        /*  The backgroundColor property changes nothing, and the tintColor property
            seems to be completely ineffective on iOS 7. I have resorted to using a
            custom background view instead.
            
            http://stackoverflow.com/questions/15604900/ios-uitableviewheaderfooterview-unable-to-change-background-color
        */
        view.backgroundView = [[UIView alloc] initWithFrame:view.frame];
        view.backgroundView.backgroundColor = TABLE_HEADER_COLOR;

        // day, e.g. Friday
        dayNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 200, 40)];
        dayNameLabel.textColor = [UIColor whiteColor];
        dayNameLabel.tag       = 1;
        dayNameLabel.font      = [UIFont boldSystemFontOfSize:25];
        [view.contentView addSubview:dayNameLabel];

        // date, e.g. March 28
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        dateNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(screenWidth - 165, 0, 150, 40)];
        dateNameLabel.textAlignment = NSTextAlignmentRight;
        dateNameLabel.textColor     = [UIColor whiteColor];
        dateNameLabel.tag           = 2;
        [view.contentView addSubview:dateNameLabel];
        
    }
    
    // update text.
    dayNameLabel.text  = self.location.hourlyForecast[section][0][0];
    dateNameLabel.text = self.location.hourlyForecast[section][0][1];
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == [self.location.hourlyForecast count]) return 0;
    return 40;
}

#pragma mark - Interface actions

// refresh button was tapped.
- (void)refreshButtonTapped {

    // fetch most recent data.
    [self.location fetchHourlyForecast:tenDay];
    [self.location commitRequest];

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
