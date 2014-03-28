//
//  WAConditionDetailTVC.h
//  Weather
//
//  Created by Mitchell Cooper on 1/22/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

@interface WAConditionDetailTVC : UITableViewController {
    UIImage         *background;                            // the current background image
    UIBarButtonItem *refreshButton;                         // the refresh button in navbar
}

@property (weak) WALocation *location;                      // weak reference to the location

- (instancetype)initWithLocation:(WALocation *)location;    // initialize with a location
- (void)update;                                             // update the displayed information

@end
