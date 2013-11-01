//
//  WAAppDelegate.h
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/28/13.
//  Copyright (c) 2013 Really Good. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#define APP_DELEGATE ((WAAppDelegate *)([UIApplication sharedApplication].delegate))
#define DEFAULTS [NSUserDefaults standardUserDefaults]
#define WU_API_KEY @"ffd9e1544413efef"
#define FMT(str, ...) [NSString stringWithFormat:str, ##__VA_ARGS__]
#define L(str) NSLocalizedString(str, nil)

@class WALocationManager, WAWeatherVC, WALocation, WANavigationController;

@interface WAAppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate> {
    CLLocationManager       *coreLocationManager;
    UIPageViewController    *pageVC;
}

@property (strong, nonatomic) UIWindow *window;
@property WANavigationController *nc;
@property WALocationManager *locationManager;
@property WALocation *currentLocation;


@end
