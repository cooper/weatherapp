//
//  WAConditionDetailTVC.h
//  Weather
//
//  Created by Mitchell Cooper on 1/22/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

@interface WAConditionDetailTVC : UITableViewController {
    NSArray *currentConditions;
    NSArray *forecastedConditions;
    UIImage *background;
}

@property WALocation *location;

- (id)initWithBackground:(UIImage *)background location:(WALocation *)location;

@end
