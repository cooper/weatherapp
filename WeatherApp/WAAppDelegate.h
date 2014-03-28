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

#define DEFAULTS [NSUserDefaults standardUserDefaults]

// Wunderground API settings.

#define WU_API_KEY          @"ffd9e1544413efef"
#define TEMP_NONE           -999

// Colors.
#define DARK_BLUE_COLOR     [UIColor colorWithRed:  0       green:0 blue:100./255. alpha:1]
#define LLLL_BLUE_COLOR     [UIColor colorWithRed: 20./255. green:200./255. blue:1 alpha:1]
#define  LLL_BLUE_COLOR     [UIColor colorWithRed:  0./255. green:180./255. blue:1 alpha:1]
#define   LL_BLUE_COLOR     [UIColor colorWithRed:  0./255. green:170./255. blue:1 alpha:1]
#define    L_BLUE_COLOR     [UIColor colorWithRed:  0./255. green:160./255. blue:1 alpha:1]
#define      BLUE_COLOR     [UIColor colorWithRed:  0./255. green:150./255. blue:1 alpha:1]
#define TABLE_COLOR         [UIColor colorWithRed:235./255. green:240./255. blue:1 alpha:1]

// Convenience macro functions.

#define FMT(str, ...)       [NSString stringWithFormat:str, ##__VA_ARGS__]
#define URL_ESC(str)        [str stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
#define OR(this, otherwise) (this ? this : otherwise)
#define SETTING(setting)    [DEFAULTS boolForKey:setting]
#define SETTING_IS(setting, value) [[DEFAULTS objectForKey:setting] isEqualToString:value]
#define STR_OR_NIL(str)     (str && [str length] ? str : nil)

// Types.

typedef void(^WACallback)(void);    // WALocation's callback type

// Predeclare class names for use throughout all headers.
@class
    WALocationManager,
    WALocation,
    WAPageViewController,
    WANavigationController,
    WALocationListTVC,
    WALocationCell,
    WANewLocationTVC,
    WASettingsTVC,
    WAWeatherVC,
    WAConditionDetailTVC,
    WADailyForecastTVC,
    WAHourlyForecastTVC;

#pragma mark - Application delegate

@interface WAAppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate> {
    CLLocationManager       *coreLocationManager;       // Core Location API manager
    NSUInteger              activityCount;              // reference count for activity indicator
    BOOL                    gotLocation;                // device has been located initially
    WACallback              onFetchedConditions;        // callback for after fetch.
}

@property (strong, nonatomic) UIWindow *window;         // the application window
@property WANavigationController *navigationController; // the main navigation controller
@property WAPageViewController   *pageViewController;   // the location page view controller (swipe up/down)
@property WALocationManager      *locationManager;      // our location manager
@property (readonly) WALocation  *currentLocation;      // the current location object
@property NSDate                 *lastSettingsChange;   // time of last settings change

- (void)saveLocationsInDatabase;                        // updates user defaults database
- (void)beginActivity;                                  // increase activity counter
- (void)endActivity;                                    // decrease activity counter

@end

FOUNDATION_EXPORT WAAppDelegate *appDelegate;           // app delegate object
FOUNDATION_EXPORT float temp_safe(id);                  // temperature value check function
