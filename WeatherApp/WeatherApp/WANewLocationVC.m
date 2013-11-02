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
#import "WALocationManager.h"
#import "WALocation.h"
#import "WATableViewController.h"

@implementation WANewLocationVC

#pragma mark - Table view controller

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        results = [NSMutableArray array];//[NSMutableArray array];
    }
    
    return self;
}

#pragma  mark - View controller

- (void)viewWillAppear:(BOOL)animated {
    //NSLog(@"Loading data in new location table view");
    //[self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
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
    return [results count] == 0 ? 1 : [results count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:indexPath.section ?  @"cell" : @"inputcell"];
    
    cell.showsReorderControl = NO;

    // input section.
    if (indexPath.section == 0) {
        
        if (!textField) {
            textField = [[UITextField alloc] initWithFrame:CGRectMake(15, 10, 280, 30)];
            [textField becomeFirstResponder];
        }
        
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

        return cell;
    }
    
    if ([results count] == 0) {
        cell.textLabel.text = L(@"No locations found");
    }
    else cell.textLabel.text = results[indexPath.row][@"longName"];
    
    cell.textLabel.adjustsFontSizeToFitWidth = YES;

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return L(@"Search");
    return L(@"Results");
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return nil;
}


// prevent highlighting of current location cells.
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) return NO;
    if ([results count] == 0)   return NO;
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"selected: %@", results[indexPath.row]);
    WALocation *location = [APP_DELEGATE.locationManager createLocationFromDictionary:results[indexPath.row]];
    
    // fetch the conditions. then, update the sections if something changed.
    NSString *before = results[indexPath.row][@"longName"];
    [location fetchCurrentConditionsThen:^{
        if (APP_DELEGATE.nc && APP_DELEGATE.nc.tvc && ![before isEqualToString:location.fullName])
            [APP_DELEGATE.nc.tvc.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
    }];
    [APP_DELEGATE.nc popToRootViewControllerAnimated:YES];
}

#pragma mark - Suggestion lookups

- (void)lookupSuggestion:(NSString *)firstPart {

    // empty. just clear it.
    if (![firstPart length]) {
        [results removeAllObjects];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        return;
    }
    
    NSLog(@"Looking up suggestions for %@", firstPart);
    
    // figure the API URL and create a request.
    NSString *str = FMT(@"http://api.geonames.org/searchJSON?name_startsWith=%@&maxRows=10&username=" GEO_LOOKUP_USERNAME, URL_ESC(firstPart));
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:str]];
    
    // send the request asynchronously.
    NSDate *date = [NSDate date];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
    
        // the user already selected something, so just forget about this request.
        // or if the user has typed since this request started, forget it.
        if (selectedOne || [lastTypeDate laterDate:date] == lastTypeDate) return;
        
        // a connection error occurred.
        if (connectionError) {
            NSLog(@"Location lookup connection error: %@", connectionError);
            return;
        }
        
        // decode the JSON.
        NSError *jsonError;
        NSDictionary *obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        
        // a JSON error occured.
        if (jsonError) {
            NSLog(@"JSON error: %@", jsonError);
            return;
        }
        
        // clear the results from the last request.
        [results removeAllObjects];
        
        // add the new results.
        for (NSDictionary *place in obj[@"geonames"]) {
            NSMutableString *name = [place[@"name"] mutableCopy];
            
            // this must be a city.
            BOOL skipPlace = NO;
            if ([place[@"fclName"] rangeOfString:@"city"].location == NSNotFound) {
                NSLog(@"%@ (%@) appears to not be a city; skipping", name, place[@"fclName"]);
                skipPlace = YES;
            }
            
            // ensure that this place has the information we need.
            for (NSString *key in @[@"name", @"countryName", @"countryCode"]) {
                if (place[key]) continue;
                NSLog(@"No %@ found for %@; skipping", key, name);
                skipPlace = YES;
            }
            if (skipPlace) continue;
            
            // determine the long name of this place.
            for (NSString *key in @[@"adminName3", @"adminName2", @"adminName1", @"countryName"]) {
                if (!place[key]) continue;
                if (![place[key] length]) continue;
                NSLog(@"%@: %@", key, place[key]);
                [name appendString:FMT(@", %@", place[key])];
            }
            
            // used for all types of cities.
            NSMutableDictionary *loc = [@{
                @"longName":        name,
                @"city":            place[@"name"],
                @"country":         place[@"countryName"],
                @"countryShort":    place[@"countryCode"]
            } mutableCopy];
            
            // if coordinates are available, store them as well.
            if (place[@"lat"]) loc[@"latitude"]  = [NSNumber numberWithFloat:[place[@"lat"] floatValue]];
            if (place[@"lng"]) loc[@"longitude"] = [NSNumber numberWithFloat:[place[@"lng"] floatValue]];
            
            // if this is in the United States, adminName1 is the state's full name,
            // and adminCode1 is the state's initials. in any other country, we don't care.
            if ([place[@"countryCode"] isEqualToString:@"US"]) {
                loc[@"state"]      = place[@"adminName1"];
                loc[@"stateShort"] = place[@"adminCode1"];
            }
            
            [results addObject:loc];
        }
        
        // reload section 1 of the table.
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
    }];
    
}

#pragma mark - Text field delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    lastTypeDate = [NSDate date];
    NSLog(@"Should change characters");
    [self performSelector:@selector(checkIfTypedSince:) withObject:[NSDate date] afterDelay:1];
    return YES;
}

- (void)checkIfTypedSince:(NSDate *)date {
    
    // user has typed since.
    if ([date laterDate:lastTypeDate] == lastTypeDate) return;
    
    NSLog(@"User hasn't typed for 1 seconds; looking up %@", textField.text);
    [self lookupSuggestion:textField.text];
}

@end
