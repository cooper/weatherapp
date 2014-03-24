//
//  WAConditionDetailTVC.h
//  Weather
//
//  Created by Mitchell Cooper on 1/22/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

@interface WAConditionDetailTVC : UITableViewController {
    NSArray         *currentConditions; // generated cell information
    UIImage         *background;        // the current background
    UIBarButtonItem *refreshButton;     // the refresh button in navbar
    NSDate          *lastUpdate;        // last time cell information was updated
}

@property (weak) WALocation *location;

- (id)initWithLocation:(WALocation *)location;
- (void)update;

@end
