//
//  WAConditionDetailTVCViewController.h
//  Weather
//
//  Created by Mitchell Cooper on 1/22/14.
//  Copyright (c) 2014 Really Good. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAConditionDetailTVC : UITableViewController {
    NSArray *currentConditions;
    NSArray *forecastedConditions;
}

@property WALocation *location;

@end
