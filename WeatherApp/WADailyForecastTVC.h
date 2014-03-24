//
//  WADailyForecastTVC.h
//  Weather
//
//  Created by Mitchell Cooper on 3/22/14.
//  Copyright (c) 2014 Really Good. All rights reserved.
//

@interface WADailyForecastTVC : UITableViewController {
    NSArray         *forecastedConditions;  // objective forecast information
    UIImage         *background;            // background image view
    UIBarButtonItem *refreshButton;         // refresh button in navbar
    NSMutableArray  *fakeLocations;         // forecast location objects
    UIActivityIndicatorView *indicator;     // the large indicator
    NSDate          *lastUpdate;            // last time cell information was updated
}

@property (weak) WALocation *location;

- (id)initWithLocation:(WALocation *)location;
- (void)update;

@end
