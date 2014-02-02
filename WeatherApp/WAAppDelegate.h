//
//  WAAppDelegate.h
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/28/13.
//  Copyright (c) 2013-14 Mitchell Cooper. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "WASettingsConstants.h"

#pragma mark - Macros

// Commonly-accessed properties.

#define APP_DELEGATE ((WAAppDelegate *)([UIApplication sharedApplication].delegate))
#define DEFAULTS [NSUserDefaults standardUserDefaults]

// Wunderground API settings.

#define WU_API_KEY          @"ffd9e1544413efef"
#define TEMP_NONE           -999

// Colors.

#define LLLL_BLUE_COLOR     [UIColor colorWithRed: 20./255. green:200./255. blue:1 alpha:1]
#define  LLL_BLUE_COLOR     [UIColor colorWithRed:  0./255. green:180./255. blue:1 alpha:1]
#define   LL_BLUE_COLOR     [UIColor colorWithRed:  0./255. green:170./255. blue:1 alpha:1]
#define    L_BLUE_COLOR     [UIColor colorWithRed:  0./255. green:160./255. blue:1 alpha:1]
#define      BLUE_COLOR     [UIColor colorWithRed:  0./255. green:150./255. blue:1 alpha:1]
#define TABLE_COLOR         [UIColor colorWithRed:235./255. green:240./255. blue:1 alpha:1]

// Convenience functions.

#define FMT(str, ...)       [NSString stringWithFormat:str, ##__VA_ARGS__]
#define URL_ESC(str)        [str stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
#define OR(this, otherwise) (this ? this : otherwise)
#define SETTING(setting)    [DEFAULTS boolForKey:setting]
#define SETTING_IS(setting, value) [[DEFAULTS objectForKey:setting] isEqualToString:value]

// Types.

typedef void(^WACallback)(void);    // WALocation's callback type

#pragma mark - Application delegate

@class                              // predeclare class names for use in headers
    WALocationManager,              // throughout the application's source files
    WALocation,
    WAPageViewController,
    WANavigationController,
    WALocationListTVC,
    WANewLocationTVC,
    WASettingsTVC,
    WAWeatherVC,
    WAConditionDetailTVC;

@interface WAAppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate> {
    CLLocationManager       *coreLocationManager;   // Core Location API manager
    NSUInteger              activityCount;          // reference count for activity indicator
    BOOL                    gotLocation;            // device has been located initially
    WACallback              onFetchedConditions;    // callback for after fetch.
}

@property (strong, nonatomic) UIWindow *window;     // the application window
@property WANavigationController *nc;               // the main navigation controller
@property WAPageViewController *pageVC;             // the location page view controller (swipe up/down)
@property WALocationManager *locationManager;       // our location manager
@property (readonly) WALocation *currentLocation;   // the current location object

- (void)saveLocationsInDatabase;    // updates user defaults database
- (void)beginActivity;              // increase activity counter
- (void)endActivity;                // decrease activity counter

@end
