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
#import <QuartzCore/QuartzCore.h>

#import "WASettingsConstants.h"

#pragma mark - Macros

// Convenience macro functions.

#define FMT(str, ...)       [NSString stringWithFormat:str, ##__VA_ARGS__]
#define URL_ESC(str)        [str stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
#define OR(this, otherwise) (this ? this : otherwise)
#define SETTING(setting)    [DEFAULTS boolForKey:setting]
#define SETTING_IS(setting, value) [[DEFAULTS objectForKey:setting] isEqualToString:value]
#define STR_OR_NIL(str)     (str && [str length] ? str : nil)

// Commonly-accessed properties.

#define DEFAULTS [NSUserDefaults standardUserDefaults]

// Wunderground API settings.

#define WU_API_KEY          @"ffd9e1544413efef"
#define TEMP_NONE           -999

// Drop down menu settings.

#define ITEMHEIGHT          55.
#define ITEMPADDING         12.
#define ICONPADDING         12.
#define ICONSIZE            30.
#define MENUFONT_SIZE       25.
#define MENUFONT_FAMILY     @"Helvetica-Neue"

// Colors.

#define RGBA(R, G, B, A)    [UIColor colorWithRed:R/255. green:G/255. blue:B/255. alpha:A]
#define LLLL_BLUE_COLOR     RGBA( 20., 200., 255.,  1 )     // lightest blue
#define  LLL_BLUE_COLOR     RGBA(  0., 180., 255.,  1 )     // very light blue
#define   LL_BLUE_COLOR     RGBA(  0., 170., 255.,  1 )     // lighter blue
#define    L_BLUE_COLOR     RGBA(  0., 160., 255.,  1 )     // light blue
#define      BLUE_COLOR     RGBA(  0., 150., 255.,  1 )     // base blue
#define DARK_BLUE_COLOR     RGBA(  0.,   0., 100.,  1 )     // darkest blue
#define TABLE_COLOR         RGBA(235., 240., 255.,  1 )     // solid table color
#define TABLE_COLOR_T       RGBA(235., 240., 255., .7 )     // translucent table color
#define TABLE_HEADER_COLOR  RGBA( 21., 137., 255., .95)     // table header color
#define CELL_SEL_COLOR      RGBA(  0., 150., 255., .3 )     // selected cell blue
#define L_CELL_SEL_COLOR    RGBA(235., 240., 255., .5 )     // selected cell white

// Types.

typedef void(^WALocationCallback)(NSURLResponse *res, NSDictionary *data);

// Predeclare class names for easy use throughout all headers.

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

// These instance variables are used only within the application delegate.

@interface WAAppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate> {
    CLLocationManager       *coreLocationManager;       // Core Location API manager
    NSUInteger              activityCount;              // reference count for activity indicator
    BOOL                    gotLocation;                // device has been located initially
    WALocationCallback      onFetchedConditions;        // callback for after fetch
}

// These properties are accessed throughout the app.

@property (strong, nonatomic) UIWindow *window;         // the application window
@property WANavigationController *navigationController; // the main navigation controller
@property WAPageViewController   *pageViewController;   // the location page view controller (swipe up/down)
@property NSDate                 *lastSettingsChange;   // time of last settings change

// These methods are used throughout the app.

- (void)displayAlert:(NSString *)title message:(NSString *)message; // alert convenience
- (void)saveLocationsInDatabase;                        // updates user defaults database
- (void)beginActivity;                                  // increase activity counter
- (void)endActivity;                                    // decrease activity counter

@end

// These things are used very frequently throughout almost all files.

FOUNDATION_EXPORT WAAppDelegate     *appDelegate;       // app delegate object
FOUNDATION_EXPORT WALocationManager *locationManager;   // location manager object
FOUNDATION_EXPORT float temp_safe(id);                  // temperature value check function
