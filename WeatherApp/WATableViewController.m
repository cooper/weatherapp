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
#import "WANewLocationTVC.h"
#import "WAWeatherVC.h"
#import "WASettingsTVC.h"

@interface WATableViewController ()

@end

@implementation WATableViewController

#pragma  mark - Table view controller

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
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
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = L(@"Locations");
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(goToNew)];
    //self.tableView.backgroundColor = [UIColor colorWithRed:230./255. green:240./255. blue:255./255. alpha:1];
    self.tableView.backgroundColor = TABLE_COLOR;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2) return 45;
    return IS_IPAD ? 120 : 60;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section != 1) return 1;
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
    cell.backgroundColor  = [UIColor whiteColor];
    
    //cell.textLabel.adjustsFontSizeToFitWidth = YES;

    // this is the "new" section.
    if (indexPath.section == 2) {
        cell.textLabel.text = L(@"Settings");
        return cell;
    }

    // current location cell can't be moved.
    cell.showsReorderControl = indexPath.section == 0;

    // find the location object.
    NSUInteger index     = indexPath.row + indexPath.section;
    WALocation *location = APP_DELEGATE.locationManager.locations[index];
    
    // on iPad, double the font sizes.
    CGFloat size       = cell.textLabel.font.pointSize;
    CGFloat detailSize = cell.detailTextLabel.font.pointSize;
    if (IS_IPAD) {
        size       *= 2;
        detailSize *= 2;
    }

    NSString *city   = [location.city   length] ? location.city   : L(@"Loading");
    NSString *region = [location.region length] ? location.region : @"...";
    NSString *both   = FMT(@"%@ %@", city, region);

    // make the city name bold.
    NSMutableAttributedString *name = [[NSMutableAttributedString alloc] initWithString:both attributes:nil];
    [name setAttributes:@{
        NSFontAttributeName:    [UIFont boldSystemFontOfSize:size]
    } range:NSMakeRange(0, [city length])];
    
    // make the region name smaller.
    [name setAttributes:@{
        NSFontAttributeName:            [UIFont systemFontOfSize:(size - (IS_IPAD ? 10 : 5))],
        NSForegroundColorAttributeName: [UIColor grayColor]
    } range:NSMakeRange([city length] + 1, [region length])];
    
    // set weather info.
    cell.textLabel.attributedText   = name;
    cell.detailTextLabel.textColor  = BLUE_COLOR;
    cell.detailTextLabel.font       = [UIFont systemFontOfSize:detailSize];
    cell.imageView.image            = location.conditionsImage;
    
    // FIXME: take metric into account if it's preferred.
    NSString *degrees = location.degreesF ? FMT(@"%.fº ", location.degreesF) : @"";
    cell.detailTextLabel.text = FMT(@"%@%@", degrees, OR(location.conditions, @""));
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return L(@"Current location");
    if (section == 1) return L(@"Favorite locations");
    return nil;
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
    if (indexPath.section != 1) return NO;
    return YES;
}

// prevent moving of current location cells.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // FIXME: this prevents current location rows from being moved,
    // but it does not fix the issue where custom locations can be moved up into section 0.
    if (indexPath.section != 1) return NO;
    return YES;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    //if (editing) [self.navigationItem setRightBarButtonItem:nil        animated:YES];
    //else         [self.navigationItem setRightBarButtonItem:doneButton animated:YES];
    
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

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
    
    // settings.
    else if (indexPath.section == 2) {
        WASettingsTVC *settingsTVC = [[WASettingsTVC alloc] initWithStyle:UITableViewStyleGrouped];
        [self.navigationController pushViewController:settingsTVC animated:YES];
        return;
    }
    
    // other location.
    else index = indexPath.row + 1;
    
    // set current page to this location, and dismiss the nc.
    //[APP_DELEGATE.locationManager focusLocationAtIndex:index];
    WALocation *location = APP_DELEGATE.locationManager.locations[index];
    [self.navigationController pushViewController:location.viewController animated:YES];
    //[APP_DELEGATE.pageVC view];
    
    // update database for reorder and deletion.
    [APP_DELEGATE saveLocationsInDatabase];

}

- (void)goToNew {
    WANewLocationTVC *vc = [[WANewLocationTVC alloc] initWithStyle:UITableViewStyleGrouped];
    vc.navigationItem.title = L(@"New");
    [self.navigationController pushViewController:vc animated:YES];
}

// move
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {

    // switch the locations.
    NSUInteger from = sourceIndexPath.row + 1;
    NSUInteger to    = destinationIndexPath.row + 1;
    WALocation *loc1 = APP_DELEGATE.locationManager.locations[from];
    WALocation *loc2 = APP_DELEGATE.locationManager.locations[to];
    APP_DELEGATE.locationManager.locations[to]   = loc1;
    APP_DELEGATE.locationManager.locations[from] = loc2;
    
}

// do not allow weather cells to be moved out of section 1.
- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    if (proposedDestinationIndexPath.section != sourceIndexPath.section) return sourceIndexPath;
    return proposedDestinationIndexPath;
}

- (void)updateLocationAtIndex:(NSUInteger)index {
    NSUInteger section = index == 0 ? 0 : 1;
    if (index) index--;
    NSArray *rows = @[[NSIndexPath indexPathForRow:index inSection:section]];
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

@end
