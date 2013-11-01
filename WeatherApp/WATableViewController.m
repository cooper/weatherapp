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
    if (section == 0) return 2;
    return [APP_DELEGATE.locationManager.locations count] - 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    
    // current location section.
    if (indexPath.section == 0) {
        cell.showsReorderControl = NO;
        if (indexPath.row == 1)
            cell.textLabel.text = FMT(@"%f,%f", APP_DELEGATE.currentLocation.coordinate.latitude, APP_DELEGATE.currentLocation.coordinate.longitude);
        else
            cell.textLabel.text = APP_DELEGATE.currentLocation.fullName;
        return cell;
    }
    
    WALocation *location = APP_DELEGATE.locationManager.locations[indexPath.row + 1];
    cell.textLabel.text = location.fullName;
    cell.showsReorderControl = YES;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return L(@"Current location");
    return L(@"Custom locations");
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return nil;
}


// prevent highlighting of current location cells.
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) return NO;
    return YES;
}

// prevent editing of current location cells.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) return NO;
    return YES;
}

// prevent moving of current location cells.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // FIXME: this prevents current location rows from being moved, but it does not fix the issue where custom locations can be moved up into section 0.
    if (indexPath.section == 0) return NO;
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

    // TODO: THIS IS HOW WE KNOW IF DELETE WAS PRESSED.
    if (editingStyle == UITableViewCellEditingStyleDelete) {
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // can't select current location.
    if (indexPath.section == 0) return;
    
    WANewLocationVC *vc = [[WANewLocationVC alloc] initWithStyle:UITableViewStyleGrouped];
    vc.navigationItem.title = L(@"Edit");
    [APP_DELEGATE.nc pushViewController:vc animated:YES];
}

// move
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    NSLog(@"moving %@ to %@", sourceIndexPath, destinationIndexPath);
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
