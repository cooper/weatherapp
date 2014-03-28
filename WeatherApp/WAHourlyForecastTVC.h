//
//  WAHourlyForecastTVC.h
//  Weather
//
//  Created by Mitchell Cooper on 3/22/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

@interface WAHourlyForecastTVC : UITableViewController {
    UIImage         *background;                            // background image view
    UIBarButtonItem *refreshButton;                         // refresh button in navbar
    UIActivityIndicatorView *indicator;                     // the large indicator
    NSDate          *lastUpdate;                            // last time cell information was updated
    BOOL            tenDay;                                 // use ten day forecast
}

@property (weak) WALocation *location;                      // weak reference to the location object

- (instancetype)initWithLocation:(WALocation *)location;    // initialize with a location
- (void)update;                                             // update the displayed information

@end
