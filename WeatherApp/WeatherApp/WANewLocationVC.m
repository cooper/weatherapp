//
//  WANewLocationVC.m
//  WeatherApp
//
//  Created by Mitchell Cooper on 11/1/13.
//  Copyright (c) 2013 Really Good. All rights reserved.
//

#import "WANewLocationVC.h"
#import "WAAppDelegate.h"
#import "WANavigationController.h"

@implementation WANewLocationVC


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        results = [NSMutableArray array];//[NSMutableArray array];
    }
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    //NSLog(@"Loading data in new location table view");
    //[self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonTapped)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
/*
- (void)later {
    [results addObject:@"another one"];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)muchlater {
    [results removeObject:@"hi"];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
}*/

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return 1;
    return [results count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:indexPath.section ?  @"cell" : @"inputcell"];
    
    cell.showsReorderControl = NO;

    // input section.
    if (indexPath.section == 0) {
        
        textField = [[UITextField alloc] initWithFrame:CGRectMake(110, 10, 185, 30)];
        textField.adjustsFontSizeToFitWidth = YES;
        textField.textColor = [UIColor blackColor];

            textField.keyboardType = UIKeyboardTypeDefault;
            textField.returnKeyType = UIReturnKeyDefault;
        textField.placeholder = L(@"Type to look up a location");

        textField.backgroundColor = [UIColor whiteColor];
        textField.autocorrectionType = UITextAutocorrectionTypeNo; // no auto correction support
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone; // no auto capitalization support
        
        textField.textAlignment = NSTextAlignmentLeft;
        textField.tag = 0;
        textField.delegate = self;
        
        textField.clearButtonMode = UITextFieldViewModeNever; // no clear 'x' button to the right
        [textField setEnabled: YES];
        
        [cell.contentView addSubview:textField];
        cell.textLabel.text = @"Search";
        
        return cell;
    }
    
    cell.textLabel.text = results[indexPath.row];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return nil;
    return L(@"Results");
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
    return NO;
}

// prevent moving of current location cells.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // TODO: THIS IS HOW WE KNOW IF DELETE WAS PRESSED.
    if (editingStyle == UITableViewCellEditingStyleDelete) {
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"selected: %@", indexPath);
}

// move
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    NSLog(@"moving stuff");
}


- (void)doneButtonTapped {
    NSLog(@"Tapped!");
}

- (void)lookupSuggestion:(NSString *)firstPart {
    NSLog(@"Looking up suggestions for %@", firstPart);
    NSString *str     = FMT(@"http://api.geonames.org/postalCodeSearchJSON?placename_startsWith=%@&maxRows=10&username=" GEO_LOOKUP_USERNAME, [firstPart stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:str]];
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        // TODO: handle errors here...
        NSError *error;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        NSArray *arrayOfDicts = result[@"postalCodes"];
        [results removeAllObjects];
        for (NSDictionary *place in arrayOfDicts) {
            NSMutableString *name = [place[@"placeName"] mutableCopy];
            if (place[@"adminName2"])  [name appendString:FMT(@", %@", place[@"adminName2"])];
            if (place[@"adminName1"])  [name appendString:FMT(@", %@", place[@"adminName1"])];
            if (place[@"countryCode"]) [name appendString:FMT(@", %@", place[@"countryCode"])];
            [results addObject:name];
        }
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    lastTypeDate = [NSDate date];
    NSLog(@"Should change characters");
    [self performSelector:@selector(checkIfTypedSince:) withObject:[NSDate date] afterDelay:1.5];
    return YES;
}

- (void)checkIfTypedSince:(NSDate *)date {
    
    // user has typed since.
    if ([date laterDate:lastTypeDate] == lastTypeDate) return;
    
    NSLog(@"User hasn't typed for 1.5 seconds; looking up %@", textField.text);
    [self lookupSuggestion:textField.text];
}

@end
