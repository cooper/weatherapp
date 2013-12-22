//
//  WATableViewController.h
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/31/13.
//  Copyright (c) 2013 Really Good. All rights reserved.
//

#import "BVReorderTableView.h"

@interface WALocationListTVC : UITableViewController <ReorderTableViewDelegate>

- (void)updateLocationAtIndex:(NSUInteger)index;

@property BVReorderTableView *reorderTableView;

@end
