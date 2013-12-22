//
//  WATableViewController.m
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/31/13.
//  Copyright (c) 2013 Really Good. All rights reserved.
//

#import "WALocationListTVC.h"
#import "WALocationManager.h"
#import "WALocation.h"
#import "WANavigationController.h"
#import "WAPageViewController.h"
#import "WANewLocationTVC.h"
#import "WAWeatherVC.h"
#import "WASettingsTVC.h"

@interface WALocationListTVC ()

@end

@implementation WALocationListTVC

#pragma  mark - Table view controller

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        NSLog(@"initialization");
        // Custom initialization

    }

    return self;
}

#pragma mark - View controller

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"Loading data in table view");
    [self.tableView reloadData];
    
    //self.navigationController.navigationBar.tintColor    = [UIColor whiteColor];
    //self.navigationController.navigationBar.barTintColor = BLUE_COLOR;
    //[self.navigationController setNavigationBarHidden:NO animated:animated];

}

- (void)viewDidAppear:(BOOL)animated {

    // in rare occasions, the status bar might still be hidden at this point.
    // this is just a double-check to ensure it is showing now.
    //[self.navigationController setNavigationBarHidden:NO animated:animated];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView        =
    self.reorderTableView = [[BVReorderTableView alloc] initWithFrame:self.tableView.frame style:self.tableView.style];
    self.reorderTableView.delegate = self;
    
    NSLog(@"did load");
    // remove the border between cells.
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    self.navigationItem.title = L(@"Locations");
    //self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(goToNew)];
    //self.tableView.backgroundColor = [UIColor colorWithRed:230./255. green:240./255. blue:255./255. alpha:1];
    //self.tableView.backgroundColor = TABLE_COLOR;
    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"backgrounds/clear.jpg"]];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [APP_DELEGATE.locationManager.locations count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    // find the location object.
    WALocation *location = APP_DELEGATE.locationManager.locations[indexPath.row];
    
    // is this a dummy cell?
    // dummy cells take place
    if (location.dummy) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"dummy"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"dummy"];
            cell.backgroundColor  = [UIColor clearColor];
        }
        return cell;
    };

    // find or create cell.
    // we only want to reuse a cell if our initial load is complete.
    // otherwise, a new location's cell will have another's style.
    UITableViewCell *cell;
    if (location.initialLoadingComplete)
        cell = [tableView dequeueReusableCellWithIdentifier:@"location"];
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"location"];
    
    cell.backgroundColor  = [UIColor clearColor];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.showsReorderControl = indexPath.row == 0;
    
    // font sizes.
    CGFloat size       = 25;
    CGFloat detailSize = 20;

    NSString *city   = [location.city   length] ? location.city   : @"";
    NSString *region = [location.region length] ? location.region : ([location.longName length] ? location.longName : L(@"Locating..."));
    NSString *both   = FMT(@"%@ %@", city, region);

    // make the city name bold.
    NSMutableAttributedString *name = [[NSMutableAttributedString alloc] initWithString:both attributes:nil];
    [name setAttributes:@{
        NSFontAttributeName:    [UIFont boldSystemFontOfSize:size]
    } range:NSMakeRange(0, [city length])];
    
    // make the region name smaller.
    [name setAttributes:@{
        NSFontAttributeName:            [UIFont systemFontOfSize:(size - 10)],
        NSForegroundColorAttributeName: [UIColor grayColor]
    } range:NSMakeRange([city length] + 1, [region length])];
    
//    // FI/XME: perhaps it looks better with no icons on initial load...
//    // load the image if we haven't already.
//    // this is so an image from the former run shows before the location is updated.
//    if (location.conditionsImageName && !location.conditionsImage)
//        location.conditionsImage = [UIImage imageNamed:FMT(@"icons/50/%@", location.conditionsImageName)];
    
    // if there is no image at this point, use a dummy (clear) filler.
    if (!location.conditionsImage)
        location.conditionsImage = [UIImage imageNamed:@"icons/dummy"];
    
    // here's the background.
    if (location.cellBackground) {
        UIImageView *cellBg = [[UIImageView alloc] init];
        cellBg.image        = location.cellBackground;
        cellBg.frame        = cell.bounds;
        cell.backgroundView = cellBg;
    }
    
    // here's the selected translucent blue tint.
    cell.selectedBackgroundView = [[UIView alloc] init];
    cell.selectedBackgroundView.backgroundColor = [UIColor colorWithRed:  0./255. green:150./255. blue:1 alpha:0.3];
    cell.backgroundColor = [UIColor clearColor];
    
    // if the location is loading, add an activity indicator.
    if (location.loading) {
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        indicator.frame = CGRectMake(25, 25, 0, 0);
        //indicator.color = [UIColor blueColor];
        [cell.imageView addSubview:indicator];
        [indicator startAnimating];
    }
    
    // set weather info.
    cell.textLabel.attributedText   = name;
    cell.detailTextLabel.textColor  = BLUE_COLOR;
    cell.detailTextLabel.font       = [UIFont systemFontOfSize:detailSize];
    cell.imageView.image            = location.conditionsImage;
    cell.textLabel.backgroundColor  = cell.detailTextLabel.backgroundColor = [UIColor clearColor];
    
    // text shadows.
    for (UILabel *label in @[cell.textLabel, cell.detailTextLabel]) {
        label.layer.shadowColor     = [UIColor blackColor].CGColor;
        label.layer.shadowOffset    = CGSizeMake(1, 0);
        label.layer.shadowRadius    = 2.0;
        label.layer.shadowOpacity   = 1.0;
        label.layer.masksToBounds   = NO;
        label.layer.shouldRasterize = YES;
        label.textColor             = TABLE_COLOR;
        label.adjustsFontSizeToFitWidth = YES;
        //label.baselineAdjustment = UIBaselineAdjustmentNone;
    }
    
    // make the temperature part of the sublabel bold.
    NSString *tempUnit = SETTING_IS(kTemperatureScaleSetting, kTemperatureScaleKelvin) ? @"K" : @"º";
    NSRange tempRange  = NSMakeRange(0, [location.temperature length] + 1);
    
    // if we have no conditions, leave the sublabel blank.
    if (location.conditionsAsOf) {
        NSString *tempAndConditions = FMT(@"%@%@ %@", location.temperature, tempUnit, OR(location.conditions, @""));
        
        // make the temperature part of the sublabel bold.
        NSMutableAttributedString *sublabel = [[NSMutableAttributedString alloc] initWithString:tempAndConditions];
        [sublabel addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:cell.detailTextLabel.font.pointSize + 4] range:tempRange];
        cell.detailTextLabel.attributedText = sublabel;
    }
    
    // if initial load isn't complete, remove the arrow.
    if (!location.initialLoadingComplete)
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return nil;
}

// prevent highlighting of current location cells.
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {

    WALocation *location = APP_DELEGATE.locationManager.locations[indexPath.row];
    if (!location.initialLoadingComplete) return NO;
    
    return YES;
}

// prevent editing of current location cells.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) return NO;
    return YES;
}

// prevent moving of current location cells.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row != 0;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    //if (editing) [self.navigationItem setRightBarButtonItem:nil        animated:YES];
    //else         [self.navigationItem setRightBarButtonItem:doneButton animated:YES];
    
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) return;
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        WALocation *location = APP_DELEGATE.locationManager.locations[indexPath.row];
        [APP_DELEGATE.locationManager destroyLocation:location];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    [APP_DELEGATE saveLocationsInDatabase];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // initial load not complete.
    WALocation *location = APP_DELEGATE.locationManager.locations[indexPath.row];
    if (!location.initialLoadingComplete) return;
    
    // set current page to this location, and dismiss the nc.
    [APP_DELEGATE.locationManager focusLocationAtIndex:indexPath.row];
    [self.navigationController pushViewController:APP_DELEGATE.pageVC animated:YES];
    //[APP_DELEGATE.pageVC view];
    
    // update database for reorder and deletion.
    [APP_DELEGATE saveLocationsInDatabase];

}

- (void)goToNew {
    WANewLocationTVC *vc = [[WANewLocationTVC alloc] initWithStyle:UITableViewStyleGrouped];
    [self.navigationController pushViewController:vc animated:YES];
}

// move
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {

    // switch the locations.
    NSUInteger from = sourceIndexPath.row;
    NSUInteger to    = destinationIndexPath.row;
    WALocation *loc1 = APP_DELEGATE.locationManager.locations[from];
    WALocation *loc2 = APP_DELEGATE.locationManager.locations[to];
    APP_DELEGATE.locationManager.locations[to]   = loc1;
    APP_DELEGATE.locationManager.locations[from] = loc2;
    
    [APP_DELEGATE saveLocationsInDatabase];

}

// do not allow weather cells to be moved out of section 1.
- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    if (proposedDestinationIndexPath.row == 0) return sourceIndexPath;
    return proposedDestinationIndexPath;
}

- (void)updateLocationAtIndex:(NSUInteger)index {
    NSArray *rows = @[[NSIndexPath indexPathForRow:index inSection:0]];
    [self.tableView reloadRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationFade];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here, for example:
    // Create the next view controller.
    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];

    // Pass the selected object to the new view controller.
    
    // Push the view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
}
 
 */

#pragma mark - Reorderable table delegate

- (id)saveObjectAndInsertBlankRowAtIndexPath:(NSIndexPath *)indexPath {
    WALocation *location = APP_DELEGATE.locationManager.locations[indexPath.row];
    [APP_DELEGATE.locationManager.locations replaceObjectAtIndex:indexPath.row withObject:[WALocation newDummy]];
    return location;
}

// This method is called when the selected row is dragged to a new position. You simply update your
// data source to reflect that the rows have switched places. This can be called multiple times
// during the reordering process
- (void)moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    [self tableView:self.tableView moveRowAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
}

// This method is called when the selected row is released to its new position. The object is the same
// object you returned in saveObjectAndInsertBlankRowAtIndexPath:. Simply update the data source so the
// object is in its new position. You should do any saving/cleanup here.
- (void)finishReorderingWithObject:(id)object atIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%@, %ld, %ld", object, (long)indexPath.section, (long)indexPath.row);
    APP_DELEGATE.locationManager.locations[indexPath.row] = object;
}

@end
