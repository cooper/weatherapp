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
#import "WALocationCell.h"

@implementation WAConditionDetailTVC

// initialize with a location.
- (instancetype)initWithLocation:(WALocation *)location {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) self.location = location;
    return self;
}

#pragma mark - Table view controller

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.titleView = [appDelegate.pageViewController menuLabelWithTitle:@"Details"];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorInset = UIEdgeInsetsZero;

    // refresh button.
    refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshButtonTapped)];
    self.navigationItem.rightBarButtonItem = refreshButton;
}

// update if settings have been changed.
- (void)viewWillAppear:(BOOL)animated {
    [self update:NO];
}

#pragma mark - Weather info

- (void)update {
    [self update:YES];
}

// update the displayed information if necessary.
- (void)update:(BOOL)animated {
    
    // update table.
    [self.location updateExtensiveDetails];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.location.extensiveDetails count] + 2; // plus header and maps
}

// the first cell is the location cell.
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath.row) return 100;
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;

    // show the location cell for this location.
    // there will only be one, so it will not be reused.
    if (!indexPath.row) {
        WALocationCell *lcell = [[WALocationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        lcell.location = self.location;
        lcell.backgroundView = nil;
        return lcell;
    }
    
    // open in maps button.
    // also only one of these; it will not be reused.
    if (indexPath.row == [self.location.extensiveDetails count] + 1) {
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
            cell.textLabel.font = [UIFont boldSystemFontOfSize:cell.textLabel.font.pointSize];
        }
        
        // detail for current conditions.
        cell.textLabel.text       = self.location.extensiveDetails[indexPath.row - 1][0];
        cell.detailTextLabel.text = self.location.extensiveDetails[indexPath.row - 1][1];
    }

    // for all non-location cells.
    cell.backgroundColor = [UIColor colorWithRed:235./255. green:240./255. blue:1 alpha:0.6];
    cell.detailTextLabel.textColor = DARK_BLUE_COLOR;
    
    return cell;
}

// disable selection of cells.
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == [self.location.extensiveDetails count] + 1) return YES;
    return NO;
}

// selected "open in maps" button.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row != [self.location.extensiveDetails count] + 1) return;
    NSURL *url = [NSURL URLWithString:FMT(@"http://maps.apple.com/?q=%f,%f", self.location.latitude, self.location.longitude)];
    [[UIApplication sharedApplication] openURL:url];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Interface actions

// refresh button was tapped.
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
