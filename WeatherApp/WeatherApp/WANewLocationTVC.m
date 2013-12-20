//
//  WANewLocationVC.m
//  WeatherApp
//
//  Created by Mitchell Cooper on 11/1/13.
//  Copyright (c) 2013 Really Good. All rights reserved.
//

#import "WANewLocationTVC.h"
#import "WANavigationController.h"
#import "WALocationManager.h"
#import "WALocation.h"
#import "WALocationListTVC.h"

@implementation WANewLocationTVC

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
    self.tableView.backgroundColor = TABLE_COLOR;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [textField becomeFirstResponder];
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
        
        if (!textField) {
            textField = [[UITextField alloc] initWithFrame:CGRectMake(15, 10, 280, 30)];
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
    
    cell.textLabel.text = results[indexPath.row][@"longName"];
    
    cell.textLabel.adjustsFontSizeToFitWidth = YES;

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return L(@"Search");
    return nil;
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
    //NSString *before = results[indexPath.row][@"longName"];
    [location fetchCurrentConditions];
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
    NSString *str     = FMT(@"http://autocomplete.wunderground.com/aq?query=%@&h=1&ski=1&features=1", URL_ESC(firstPart));
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:str]];
    
    // send the request asynchronously.
    NSDate *date = [NSDate date];
    [APP_DELEGATE beginActivity];
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
    
    
        // the user already selected something, so just forget about this request.
        // or if the user has typed since this request started, forget it.
        if (selectedOne || [lastTypeDate laterDate:date] == lastTypeDate) return;
        
        // a connection error occurred.
        if (connectionError) {
            NSLog(@"Location lookup connection error: %@", connectionError);
            [APP_DELEGATE endActivity];
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
        for (NSDictionary *place in obj[@"RESULTS"]) {
            // name type city c zmw tz tzs l(/q)
            // this must be a city.

            BOOL skipPlace = NO;
            
            // ensure that this place has the information we need.
            for (NSString *key in @[@"c", @"l", @"name"]) {
                if (place[key]) continue;
                NSLog(@"No %@ found for %@; skipping", key, place[@"name"]);
                skipPlace = YES;
            }
            
            if (![place[@"type"] isEqualToString:@"city"]) {
                NSLog(@"%@ (%@) appears to not be a city; skipping", place[@"name"], place[@"fclName"]);
                skipPlace = YES;
            }
            
            if (skipPlace) continue;

            // used for all types of cities.
            NSMutableDictionary *loc = [@{
                @"longName":        place[@"name"],
                @"l":               place[@"l"],
                @"countryShort":    place[@"c"]
            } mutableCopy];

            [results addObject:loc];
            
        }
        
        // reload section 1 of the table.
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [APP_DELEGATE endActivity];
        
    }];
    
}

#pragma mark - Text field delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    lastTypeDate = [NSDate date];
    NSLog(@"Should change characters");
    [self performSelector:@selector(checkIfTypedSince:) withObject:[NSDate date] afterDelay:0.5];
    return YES;
}

- (void)checkIfTypedSince:(NSDate *)date {
    
    // user has typed since.
    if ([date laterDate:lastTypeDate] == lastTypeDate) return;
    
    NSLog(@"User hasn't typed for 0.5 seconds; looking up %@", textField.text);
    [self lookupSuggestion:textField.text];
}

#pragma mark - Keyboard notifications

- (void)keyboardWasShown:(NSNotification*)aNotification {
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize      = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    // adjust the scrollview insets.
    UIEdgeInsets currentInsets           = self.tableView.contentInset;
    self.tableView.contentInset          =
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(
        0.0             + currentInsets.top,
        0.0             + currentInsets.left,
        kbSize.height   + currentInsets.bottom,
        0.0             + currentInsets.right
    );

    // make sure the text input field is visible.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, textField.frame.origin) ) {
        CGPoint scrollPoint = CGPointMake(0.0, textField.frame.origin.y - kbSize.height);
        [self.tableView setContentOffset:scrollPoint animated:YES];
    }
    
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize      = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    // reset to former insets.
    UIEdgeInsets currentInsets           = self.tableView.contentInset;
    self.tableView.contentInset          =
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(
       currentInsets.top,
       currentInsets.left,
       currentInsets.bottom - kbSize.height,
       currentInsets.right
    );
    
}

@end
