//
//  WADailyForecastTVC.m
//  Weather
//
//  Created by Mitchell Cooper on 3/22/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

#import "WADailyForecastTVC.h"
#import "WALocation.h"
#import "WALocationListTVC.h"
#import "UITableView+Reload.h"
#import "WAPageViewController.h"
#import "WALocationCell.h"

@implementation WADailyForecastTVC

// initialize with a location.
- (instancetype)initWithLocation:(WALocation *)location {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        conditions    = [NSMutableArray array];
        self.location = location;
    }
    return self;
}
        

#pragma mark - Table view controller

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // forecast not yet obtained.
    if (!self.location.forecastResponse)
        [self.location fetchForecast];
    
    self.navigationItem.titleView = [appDelegate.pageViewController menuLabelWithTitle:@"Daily forecast"];
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
    [self.location updateDailyForecast];
    
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
    return [self.location.forecastResponse count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.location.dailyForecast[section][@"cells"] count] + 1; // plus header
}

// the location cells are all row 0.
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath.row) return 100;
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    // artificial location row of a future day.
    if (!indexPath.row) {
        WALocationCell *lcell = (WALocationCell *)[tableView dequeueReusableCellWithIdentifier:@"location"];
        if (!lcell) {
            lcell = [[WALocationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"location"];
            lcell.isFakeLocation = YES;
        }
        lcell.location = self.location.dailyForecast[indexPath.section][@"location"];
        return lcell;
    }
    
    // generic base cell.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) cell       = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    cell.backgroundColor  = [UIColor colorWithRed:235./255. green:240./255. blue:1 alpha:0.6];
    cell.detailTextLabel.textColor = DARK_BLUE_COLOR;

    // detail label on a forecast.
    cell.textLabel.text          = self.location.dailyForecast[indexPath.section][@"cells"][indexPath.row - 1][0];
    cell.detailTextLabel.text    = self.location.dailyForecast[indexPath.section][@"cells"][indexPath.row - 1][1];
    cell.textLabel.numberOfLines = 0;
    
    return cell;
}

// disable selection of cells.
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

// header views. these are reused.
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == [self.location.dailyForecast count]) return nil;
    NSDictionary *dict = self.location.dailyForecast[section];
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
        view.backgroundView.backgroundColor = [UIColor colorWithRed:21./255. green:137./255. blue:1 alpha:0.95];

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
    dayNameLabel.text  = dict[@"dayName"];
    dateNameLabel.text = dict[@"dateName"];
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
}

#pragma mark - Interface actions

// refresh button was tapped.
- (void)refreshButtonTapped {

    // fetch most recent data.
    [self.location fetchForecast];
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
