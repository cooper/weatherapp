//
//  WAHourlyForecastTVC.h
//  Weather
//
//  Created by Mitchell Cooper on 3/22/14.
//  Copyright (c) 2014 Really Good. All rights reserved.
//

@interface WAHourlyForecastTVC : UITableViewController

@property (weak) WALocation *location;

- (id)initWithLocation:(WALocation *)location;

@end
