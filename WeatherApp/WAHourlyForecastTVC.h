//
//  WAHourlyForecastTVC.h
//  Weather
//
//  Created by Mitchell Cooper on 3/22/14.
//  Copyright (c) 2014 Really Good. All rights reserved.
//

@interface WAHourlyForecastTVC : UITableViewController {
    UIImage         *background;            // background image view
    UIBarButtonItem *refreshButton;         // refresh button in navbar
    UIActivityIndicatorView *indicator;     // the large indicator
    NSMutableArray  *fakeLocations;         // forecast location objects
    NSMutableArray  *forecasts;             // array containing hourly forecast data
    NSUInteger      lastDay;                // the day in the month of the last hour checked
    NSUInteger      currentDayIndex;        // the index of the current day, starting at 0
    NSMutableArray  *daysAdded;             // track which days added to say "next" weekday
}

@property (weak) WALocation *location;

- (id)initWithLocation:(WALocation *)location;
- (void)update;

@end
