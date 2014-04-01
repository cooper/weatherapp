//
//  WANewLocationVC.h
//  WeatherApp
//
//  Created by Mitchell Cooper on 11/1/13.
//  Copyright (c) 2013-14 Mitchell Cooper. All rights reserved.
//

@interface WANewLocationTVC : UITableViewController <UITextFieldDelegate> {
    NSMutableArray *results;    // array of search results
    NSDate *lastTypeDate;       // time of last typing event (key press)
    UITextField *textField;     // the search text field in the first row
    BOOL selectedOne;           // true if the user selected a location result
    UIActivityIndicatorView *indicator; // large activity indicator
}

@end