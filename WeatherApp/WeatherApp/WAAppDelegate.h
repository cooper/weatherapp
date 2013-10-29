//
//  WAAppDelegate.h
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/28/13.
//  Copyright (c) 2013 Really Good. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#define WU_API_KEY @"ffd9e1544413efef"
#define FMT(str, ...) [NSString stringWithFormat:str, ##__VA_ARGS__]

@class WALocationManager, WAWeatherVC, WALocation;

@interface WAAppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate> {
    WALocationManager       *locationManager;
    CLLocationManager       *coreLocationManager;
    UIPageViewController    *pageVC;
    WALocation              *currentLocation;
}

@property (strong, nonatomic) UIWindow *window;

@end
