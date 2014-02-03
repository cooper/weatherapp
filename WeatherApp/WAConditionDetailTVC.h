//
//  WAConditionDetailTVC.h
//  Weather
//
//  Created by Mitchell Cooper on 1/22/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

@interface WAConditionDetailTVC : UITableViewController {
    NSArray         *currentConditions;
    NSArray         *forecastedConditions;
    UIImage         *background;
    UIBarButtonItem *refreshButton;
    NSMutableArray  *fakeLocations;
}

@property WALocation *location;

- (id)initWithLocation:(WALocation *)location;
- (void)update;

@end
