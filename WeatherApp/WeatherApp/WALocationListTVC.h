//
//  WALocationListTVC.h
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/31/13.
//  Copyright (c) 2013-14 Mitchell Cooper. All rights reserved.
//

#import "BVReorderTableView.h"

@interface WALocationListTVC : UITableViewController <ReorderTableViewDelegate, UIScrollViewDelegate>

- (void)updateLocationAtIndex:(NSUInteger)index;
+ (void)applyWeatherInfo:(WALocation *)location toCell:(UITableViewCell *)cell;

@property BVReorderTableView *reorderTableView;

@end
