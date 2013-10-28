//
//  WAAppDelegate.h
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/28/13.
//  Copyright (c) 2013 Really Good. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@class WALocationManager;

@interface WAAppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate> {
    WALocationManager       *locationManager;
    CLLocationManager       *coreLocationManager;
    UIPageViewController    *pageViewController;
    UIViewController        *mainViewController;
}

@property (strong, nonatomic) UIWindow *window;

@end
