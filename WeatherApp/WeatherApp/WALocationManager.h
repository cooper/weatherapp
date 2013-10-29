//
//  WALocationManager.h
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/28/13.
//  Copyright (c) 2013 Really Good. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WALocation;

@interface WALocationManager : NSObject <UIPageViewControllerDataSource>

@property NSMutableArray *locations;

- (WALocation *)createLocation;

@end
