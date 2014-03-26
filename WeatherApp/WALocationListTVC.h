//
//  WALocationListTVC.h
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/31/13.
//  Copyright (c) 2013-14 Mitchell Cooper. All rights reserved.
//

#import "ATSDragToReorderTableViewController.h"

@interface WALocationListTVC : ATSDragToReorderTableViewController <UIScrollViewDelegate>

- (void)updateLocationAtIndex:(NSUInteger)index;

@end
