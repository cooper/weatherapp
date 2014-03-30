//
//  WANewLocationVC.m
//  WeatherApp
//
//  Created by Mitchell Cooper on 11/1/13.
//  Copyright (c) 2013-14 Mitchell Cooper. All rights reserved.
//

#import "WANewLocationTVC.h"
#import "WANavigationController.h"
#import "WALocationManager.h"
#import "WALocation.h"
#import "WALocationListTVC.h"

@implementation WANewLocationTVC

#pragma mark - Table view controller

- (void)viewDidLoad {
    [super viewDidLoad];
    results = [NSMutableArray array];
    
    // keyboard notifications.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:)     name:UIKeyboardDidShowNotification  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    
    self.navigationItem.title = @"New favorite";

    // background.
    self.tableView.backgroundColor = TABLE_COLOR;
    self.tableView.backgroundView  = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"backgrounds/clear.jpg"]];

}

- (void)viewDidAppear:(BOOL)animated {

    // scroll back to the top with this silly rect.
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    
    // select the text field and bring up the keyboard.
    [textField becomeFirstResponder];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2; // one for text field, one for results
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 1; // text field
    return [results count];     // results
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;

    // input section.
    if (indexPath.section == 0) {
        
        // this will not be reused.
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        
        if (!textField)
            textField = [[UITextField alloc] initWithFrame:CGRectMake(15, 10, 280, 30)];
        
        textField.placeholder               = @"Search locations...";
        textField.backgroundColor           = [UIColor clearColor];
        textField.autocorrectionType        = UITextAutocorrectionTypeNo;
        textField.autocapitalizationType    = UITextAutocapitalizationTypeNone;
        textField.adjustsFontSizeToFitWidth = YES;
        textField.delegate                  = self;
        [cell.contentView addSubview:textField];
        
        cell.backgroundColor = TABLE_COLOR;
        return cell;
    }
    
    // result section.
    cell = [self.tableView dequeueReusableCellWithIdentifier:@"result"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"result"];
        cell.backgroundColor     = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
    }
    
    cell.textLabel.text = results[indexPath.row][@"longName"];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) return NO;
    if ([results count]   == 0) return NO;
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

// a result was selected.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    // create a location using the data we generated in lookupSuggestion:
    WALocation *location = [appDelegate.locationManager createLocationFromDictionary:results[indexPath.row]];
    
    // fetch the conditions; then, return to the location list.
    [location fetchCurrentConditions];
    [location commitRequest];
    [self.navigationController popToRootViewControllerAnimated:YES];
    
}

#pragma mark - Suggestion lookups

// look up something (firstPart = the query so far)
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
    [appDelegate beginActivity];
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        [appDelegate endActivity];

    
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
                NSLog(@"%@ (%@) appears to not be a city; skipping", place[@"name"], place[@"type"]);
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
        
    }];
    
}

#pragma mark - Text field delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    lastTypeDate = [NSDate date];
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    [self performSelector:@selector(checkIfTypedSince:) withObject:[NSDate date] afterDelay:0.5];
    return YES;
}

// check if the user has typed since a half-second ago.
- (void)checkIfTypedSince:(NSDate *)date {
    
    // user has typed since.
    if ([date laterDate:lastTypeDate] == lastTypeDate) return;
    
    NSLog(@"User hasn't typed for 0.5 seconds; looking up %@", textField.text);
    [self lookupSuggestion:textField.text];
}

#pragma mark - Keyboard notifications

// the keyboard WAS shown.
- (void)keyboardWasShown:(NSNotification*)aNotification {
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize      = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    // already adjusted this way.
    if (self.tableView.scrollIndicatorInsets.bottom >= kbSize.height) return;
    
    // adjust the scrollview insets.
    UIEdgeInsets currentInsets           = self.tableView.contentInset;
    self.tableView.contentInset          =
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(
        currentInsets.top,
        currentInsets.left,
        currentInsets.bottom + kbSize.height,
        currentInsets.right
    );

    // make sure the text input field is visible.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, textField.frame.origin) ) {
        CGPoint scrollPoint = CGPointMake(0.0, textField.frame.origin.y - kbSize.height);
        [self.tableView setContentOffset:scrollPoint animated:YES];
    }
    
}

// the keyboard WILL hide.
- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize      = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    // not adjusted.
    if (self.tableView.scrollIndicatorInsets.bottom < kbSize.height) return;
    
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
