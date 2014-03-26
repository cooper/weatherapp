//
//  WAConditionDetailTVC.h
//  Weather
//
//  Created by Mitchell Cooper on 1/22/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

@interface WAConditionDetailTVC : UITableViewController {
    UIImage         *background;        // the current background
    UIBarButtonItem *refreshButton;     // the refresh button in navbar
}

@property (weak) WALocation *location;

- (id)initWithLocation:(WALocation *)location;
- (void)update;

@end
