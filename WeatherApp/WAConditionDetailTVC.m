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
    if (!indexPath.row) {
        WALocationCell *lcell = [tableView dequeueReusableCellWithIdentifier:@"location"];
        if (!lcell) lcell     = [[WALocationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"location"];
        lcell.location        = self.location;
        lcell.backgroundView  = nil;
        return lcell;
    }
    
    // open in maps button.
    if (indexPath.row == [self.location.extensiveDetails count] + 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"maps"];
        if (!cell)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"maps"];
        
        // bold label.
        cell.textLabel.text         = FMT(@"Open %@ in Maps", self.location.city);
        cell.textLabel.font         = [UIFont boldSystemFontOfSize:cell.textLabel.font.pointSize];
        cell.textLabel.textColor    = [UIColor whiteColor];
        
        // white tint when select.
        cell.backgroundColor        = BLUE_COLOR;
        cell.selectedBackgroundView = [UIView new];
        cell.selectedBackgroundView.backgroundColor = L_CELL_SEL_COLOR;
        
        // globe menu icon.
        UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icons/menu/list"]];
        icon.frame        = CGRectMake(cell.contentView.bounds.size.width - 40, 10, 30, 30);
        [cell.contentView addSubview:icon];
        
    }
    
    // detail cell.
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"detail"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"detail"];
            cell.textLabel.font  = [UIFont boldSystemFontOfSize:cell.textLabel.font.pointSize];
            cell.backgroundColor = TABLE_COLOR_T;
            cell.detailTextLabel.textColor = DARK_BLUE_COLOR;
        }
        
        NSArray *row = self.location.extensiveDetails[indexPath.row - 1];
        
        // detail for current conditions.
        cell.textLabel.text       = row[0];
        cell.detailTextLabel.text = row[1];
        
        // country flag.
        UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:2];
        if ([row[0] isEqualToString:@"Country"]) {
            
            // not yet created.
            if (!imageView) {
                imageView     = [UIImageView new];
                imageView.tag = 2;
            }

            // find the image.
            UIImage *image    = [UIImage imageNamed:FMT(@"flags/%@", [row[1] lowercaseString])];
            if (!image) image = [UIImage imageNamed:@"flags/unknown"];
            imageView.image = image;
            
            // update frame accordingly.
            imageView.frame = CGRectMake(
                250,
                (cell.contentView.frame.size.height - image.size.height) / 2,
                image.size.width,
                image.size.height
            );
            [cell.contentView addSubview:imageView];
            
        }
        else imageView.image = nil;
        
    }
    
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
    [self.location commitRequest];

    // loading and refresh button is visible.
    if (self.location.loading && self.navigationItem.rightBarButtonItem == refreshButton) {
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [indicator startAnimating];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:indicator];
        [self.navigationItem setRightBarButtonItem:item animated:YES];
    }
    
}


@end
