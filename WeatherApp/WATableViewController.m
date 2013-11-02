//
//  WATableViewController.m
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/31/13.
//  Copyright (c) 2013 Really Good. All rights reserved.
//

#import "WATableViewController.h"
#import "WAAPPDelegate.h"
#import "WALocationManager.h"
#import "WALocation.h"
#import "WANavigationController.h"
#import "WANewLocationVC.h"

@interface WATableViewController ()

@end

@implementation WATableViewController

#pragma  mark - Table view controller

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.tableView.rowHeight = 60;
    }

    return self;
}

#pragma mark - View controller

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"Loading data in table view");
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = L(@"Locations");
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonTapped)];
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return 1;
    return [APP_DELEGATE.locationManager.locations count] - 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    // TODO: make custom cells.
    // I should eventually make custom subclasses of UITableViewCell
    // that have the city name, brief description of conditions, temperature, etc.
    // and increase the height of them. However, I must keep the delete and move things in mind.
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    //cell.textLabel.font = [UIFont boldSystemFontOfSize:cell.textLabel.font.pointSize];
    cell.accessoryType    = UITableViewCellAccessoryDisclosureIndicator;
    //cell.textLabel.adjustsFontSizeToFitWidth = YES;

    // current location cell can't be moved.
    BOOL isCurrentLocation   = indexPath.section == 0;
    cell.showsReorderControl = !isCurrentLocation;

    // find the location object.
    NSUInteger index     = isCurrentLocation ? 0 : indexPath.row + 1;
    WALocation *location = APP_DELEGATE.locationManager.locations[index];
    
    // make the city name bold.
    NSString *cityRegion = FMT(@"%@ %@", location.city, location.region);
    NSMutableAttributedString *name = [[NSMutableAttributedString alloc] initWithString:cityRegion attributes:nil];
    [name setAttributes:@{
        NSFontAttributeName: [UIFont boldSystemFontOfSize:cell.textLabel.font.pointSize]
    } range:NSMakeRange(0, [location.city length])];
    
    // make the region name smaller.
    [name setAttributes:@{
        NSFontAttributeName: [UIFont systemFontOfSize:(cell.textLabel.font.pointSize - 5)]
    } range:NSMakeRange([location.city length] + 1, [location.region length])];
    
    // set weather info.
    cell.textLabel.attributedText = name;
    cell.imageView.image = location.conditionsImage;
    
    // FIXME: take metric into account if it's preferred.
    NSString *degrees = location.degreesF ? FMT(@"%.fº ", location.degreesF) : @"";
    cell.detailTextLabel.text = FMT(@"%@%@", degrees, OR(location.conditions, @""));
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return L(@"Current location");
    return L(@"Favorite locations");
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return nil;
}

// prevent highlighting of current location cells.
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row != 0) return NO;
    return YES;
}

// prevent editing of current location cells.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) return NO;
    return YES;
}

// prevent moving of current location cells.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // FIXME: this prevents current location rows from being moved,
    // but it does not fix the issue where custom locations can be moved up into section 0.
    if (indexPath.section == 0) return NO;
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

    // TODO: THIS IS HOW WE KNOW IF DELETE WAS PRESSED.
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        WALocation *location = APP_DELEGATE.locationManager.locations[indexPath.row + 1];
        [APP_DELEGATE.locationManager destroyLocation:location];
    }
    
    [self.tableView setEditing:NO animated:NO];
    [self.tableView reloadData];
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger index;
    
    // current location.
    if (indexPath.section == 0) {
        if (indexPath.row != 0) return;
        index = 0;
    }
    
    // other location.
    else index = indexPath.row + 1;
    
    // set current page to this location, and dismiss the nc.
    [APP_DELEGATE.locationManager focusLocationAtIndex:index];
    [APP_DELEGATE.pageVC dismissViewControllerAnimated:YES completion:nil];
    
    // update database for reorder and deletion.
    [APP_DELEGATE saveLocationsInDatabase];

}

// move
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    if (destinationIndexPath.section != 1) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"pls dont" message:@"can u not put that there pls thx" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"0k", nil];
        [alert show];
        return;
    }
    NSLog(@"moving %ld to %ld", (long)sourceIndexPath.row, (long)destinationIndexPath.row);
    
    // switch the locations.
    NSUInteger from = sourceIndexPath.row + 1;
    NSUInteger to    = destinationIndexPath.row + 1;
    WALocation *loc1 = APP_DELEGATE.locationManager.locations[from];
    WALocation *loc2 = APP_DELEGATE.locationManager.locations[to];
    APP_DELEGATE.locationManager.locations[to]   = loc1;
    APP_DELEGATE.locationManager.locations[from] = loc2;
    
}

- (void)updateLocations {
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Interface actions

- (void)addButtonTapped {
    NSLog(@"Tapped!");
    
    WANewLocationVC *vc = [[WANewLocationVC alloc] initWithStyle:UITableViewStyleGrouped];
    vc.navigationItem.title = L(@"New");
    [APP_DELEGATE.nc pushViewController:vc animated:YES];
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

@end
