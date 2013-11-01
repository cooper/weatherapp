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

#define NUMBER_OF_SECTIONS ([APP_DELEGATE.locationManager.locations count] - 1 + newNumber)
#define LAST_SECTION_INDEX (NUMBER_OF_SECTIONS - 1)

@interface WATableViewController ()

@end

@implementation WATableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        newNumber = 0;
    }

    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"Loading data in table view");
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return NUMBER_OF_SECTIONS; // don't include current location
    // TODO: insertRowsAtIndexPath to insert a section/row when button clicked to add new location
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"cell for row at path: %@", indexPath);
    NSLog(@"%d is greater than %d?", indexPath.section + 1, [APP_DELEGATE.locationManager.locations count] - 1);
    
    UITableViewCell *cell;
    
    WALocation *location;
    if (indexPath.section + 1 > [APP_DELEGATE.locationManager.locations count] - 1)
        (void)nil; /// FIXME
    else
        location = APP_DELEGATE.locationManager.locations[indexPath.section + 1];

        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"form"];
        cell.selectionStyle  = UITableViewCellSelectionStyleNone;
        cell.showsReorderControl = YES;
        
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(110, 10, 185, 30)];
        textField.adjustsFontSizeToFitWidth = YES;
        textField.textColor = [UIColor blackColor];
        

            textField.returnKeyType = UIReturnKeyNext;
            textField.placeholder = L(@"Required");
            textField.keyboardType = UIKeyboardTypeDefault;

        textField.backgroundColor = [UIColor whiteColor];
        textField.autocorrectionType = UITextAutocorrectionTypeNo; // no auto correction support
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone; // no auto capitalization support
        textField.textAlignment = NSTextAlignmentLeft;
        textField.tag = 0;
        //textField.delegate = self;
        
        textField.clearButtonMode = UITextFieldViewModeNever; // no clear 'x' button to the right
        [textField setEnabled: YES];
        
        [cell.contentView addSubview:textField];
        
        if (indexPath.row == 0) {
            cell.textLabel.text = @"City";
            if (location) textField.text = location.city;
        }
        if (indexPath.row == 1) {
            cell.textLabel.text = @"Region";
            if (location) textField.text = location.stateShort ? location.stateShort : location.region;
        }
    
    // Configure the cell...
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSLog(@"Request title for %d", section);
    if (section + 1 > [APP_DELEGATE.locationManager.locations count] - 1) {
        NSLog(@"greater in title");
        return L(@"New location");
    }
    WALocation *location = APP_DELEGATE.locationManager.locations[section + 1];
    return location.fullName;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    
    // FIXME: this really isn't right.
    NSLog(@"Last index: %d, section: %d", LAST_SECTION_INDEX, section);
    if (section + 1 > [APP_DELEGATE.locationManager.locations count] - 1) return L(@"In the United States, type the state initials in the region field. In any other nation, type the common name of the country.");
    return nil;
}

// move
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
}


- (void)addButtonTapped {
    NSLog(@"Tapped!");
    newNumber++;
    NSInteger section = LAST_SECTION_INDEX;
    [self.tableView insertSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationBottom];
}

- (void)editButtonTapped {
    NSLog(@"Tapped!");
    [self.tableView setEditing:YES animated:YES];
}

- (void)doneButtonTapped {
    [self.tableView setEditing:NO animated:YES];
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
