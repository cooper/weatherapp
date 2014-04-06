//
//  WALocationListTVC.m
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/31/13.
//  Copyright (c) 2013-14 Mitchell Cooper. All rights reserved.
//

#import "WALocationListTVC.h"
#import "WALocationManager.h"
#import "WALocation.h"
#import "WANavigationController.h"
#import "WAPageViewController.h"
#import "WANewLocationTVC.h"
#import "WAWeatherVC.h"
#import "WASettingsTVC.h"
#import "WALocationCell.h"

@implementation WALocationListTVC

#pragma mark - Table view controller

- (void)viewWillAppear:(BOOL)animated {
    [self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // create a reorder table view and replace the original table view with it.
    BVReorderTableView *reorderTableView = [[BVReorderTableView alloc] initWithFrame:self.tableView.frame style:UITableViewStylePlain];
    reorderTableView.delegate = self;
    self.tableView = reorderTableView;

    // remove the border between cells.
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    // navigation bar buttons.
    self.navigationItem.title = @"Locations";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(goToNew)];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"\u2699" style:UIBarButtonItemStylePlain target:self action:@selector(settingsButtonTapped)];
    
    // increase the font size of the gear character (settings button).
    [self.navigationItem.leftBarButtonItem setTitleTextAttributes:@{
        NSFontAttributeName: [UIFont fontWithName:@"Helvetica" size:25]
    } forState:UIControlStateNormal];
    
    // background.
    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"backgrounds/clear2.jpg"]];
    
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [appDelegate.locationManager.locations count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    // find the location object.
    WALocation *location = appDelegate.locationManager.locations[indexPath.row];
    
    // is this a dummy cell?
    // dummy cells take of a cell being dragged.
    if (location.dummy) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"dummy"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"dummy"];
            cell.backgroundColor = [UIColor clearColor];
            cell.alpha = 0;
        }
        return cell;
    };
    
    // find or create location cell.
    WALocationCell *cell = [tableView dequeueReusableCellWithIdentifier:@"location"];
    if (!cell)
        cell = [[WALocationCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"location"];
    
    cell.location = location;
    return cell;
}

// prevent highlighting of current location cells.
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

// prevent editing of current location cells.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    WALocation *location = appDelegate.locationManager.locations[indexPath.row];
    if (location.isCurrentLocation) return NO;
    return YES;
}

// all can move.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

// commit a deletion.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    WALocation *location = appDelegate.locationManager.locations[indexPath.row];
    if (location.isCurrentLocation) return;
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [location.manager destroyLocation:location];
        
        /*  There is a bug in iOS 7 where the last row of a tableview has a very screwy animation.
            this bug is visible even in the built-in apps of iOS! It currently cannot be avoided.
            http://stackoverflow.com/questions/20976700/problems-with-animation-when-deleting-the-last-row-of-tableview-ios7
        */
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    [appDelegate saveLocationsInDatabase];
}

// select a location.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // initial load not complete.
    WALocation *location = appDelegate.locationManager.locations[indexPath.row];

    // previous loading failed?
    if (!location.response && !location.loading) {
        [location fetchCurrentConditions];
        [location commitRequest];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        return;
    }

    // first load hasn't completed.
    if (!location.initialLoadingComplete) return;

    // set current page to this location, and dismiss the nc.
    [location.manager focusLocationAtIndex:indexPath.row];
    [self.navigationController pushViewController:appDelegate.pageViewController animated:YES];
    
    // update database for reorder and deletion.
    [appDelegate saveLocationsInDatabase];

}

// move two locations.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {

    // switch the locations.
    NSUInteger from  = sourceIndexPath.row;
    NSUInteger to    = destinationIndexPath.row;
    WALocation *loc1 = appDelegate.locationManager.locations[from];
    WALocation *loc2 = appDelegate.locationManager.locations[to];
    appDelegate.locationManager.locations[to]   = loc1;
    appDelegate.locationManager.locations[from] = loc2;
    
    [appDelegate saveLocationsInDatabase];

}

// do not allow weather cells to be moved out of section 1.
- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    return proposedDestinationIndexPath;
}

#pragma mark - Interface actions

// go to the new location view controller.
- (void)goToNew {
    WANewLocationTVC *vc = [[WANewLocationTVC alloc] initWithStyle:UITableViewStyleGrouped];
    [self.navigationController pushViewController:vc animated:YES];
}

// go to the settings view controller.
- (void)settingsButtonTapped {
    WASettingsTVC *vc = [[WASettingsTVC alloc] initWithStyle:UITableViewStyleGrouped];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Messages from WALocation

// reload the location at the given index.
- (void)updateLocationAtIndex:(NSUInteger)index {
    NSArray *rows = @[[NSIndexPath indexPathForRow:index inSection:0]];
    [self.tableView reloadRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - Reorderable table delegate

// This method is called when starting the re-ording process. You insert a blank row object into your
// data source and return the object you want to save for later. This method is only called once.
- (id)saveObjectAndInsertBlankRowAtIndexPath:(NSIndexPath *)indexPath {
    WALocation *location = appDelegate.locationManager.locations[indexPath.row];
    [location.manager.locations replaceObjectAtIndex:indexPath.row withObject:[WALocation newDummy]];
    return location;
}

// This method is called when the selected row is dragged to a new position. You simply update your
// data source to reflect that the rows have switched places. This can be called multiple times
// during the reordering process.
- (void)moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    [self tableView:self.tableView moveRowAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
}

// This method is called when the selected row is released to its new position. The object is the same
// object you returned in saveObjectAndInsertBlankRowAtIndexPath:. Simply update the data source so the
// object is in its new position. You should do any saving/cleanup here.
- (void)finishReorderingWithObject:(id)object atIndexPath:(NSIndexPath *)indexPath {
    appDelegate.locationManager.locations[indexPath.row] = object;
    [appDelegate saveLocationsInDatabase];
}

@end
