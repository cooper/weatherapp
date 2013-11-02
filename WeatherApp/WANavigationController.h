//
//  WANavigationController.h
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/30/13.
//  Copyright (c) 2013 Really Good. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WATableViewController;

@interface WANavigationController : UINavigationController

- (id)initWithMyRootController;

@property WATableViewController *tvc;

@end
