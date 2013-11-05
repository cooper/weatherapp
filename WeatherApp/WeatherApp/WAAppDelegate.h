//
//  WAAppDelegate.h
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/28/13.
//  Copyright (c) 2013 Really Good. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#pragma mark - Macros

#define APP_DELEGATE ((WAAppDelegate *)([UIApplication sharedApplication].delegate))
#define DEFAULTS [NSUserDefaults standardUserDefaults]

// Device idioms.

#define IS_IPHONE   ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
#define IS_IPAD     ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

// API settings.

#define WU_API_KEY @"ffd9e1544413efef"
#define GEO_LOOKUP_USERNAME @"cooper"

// Colors.

#define LLLL_BLUE_COLOR  [UIColor colorWithRed: 20./255. green:200./255. blue:1 alpha:1]
#define  LLL_BLUE_COLOR  [UIColor colorWithRed:  0./255. green:180./255. blue:1 alpha:1]
#define   LL_BLUE_COLOR  [UIColor colorWithRed:  0./255. green:170./255. blue:1 alpha:1]
#define    L_BLUE_COLOR  [UIColor colorWithRed:  0./255. green:160./255. blue:1 alpha:1]
#define      BLUE_COLOR  [UIColor colorWithRed:  0./255. green:150./255. blue:1 alpha:1]
#define TABLE_COLOR      [UIColor colorWithRed:235./255. green:240./255. blue:1 alpha:1]

// Convenience functions.

#define FMT(str, ...) [NSString stringWithFormat:str, ##__VA_ARGS__]
#define L(str) NSLocalizedString(str, nil)
#define URL_ESC(str) [str stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
#define OR(this, otherwise) (this ? this : otherwise)

// Types.

typedef void(^WACallback)(void);

#pragma mark - Application delegate

@class WALocationManager, WAWeatherVC, WALocation, WANavigationController;

@interface WAAppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate> {
    CLLocationManager       *coreLocationManager;
}

@property (strong, nonatomic) UIWindow *window;
@property WANavigationController *nc;
@property WALocationManager *locationManager;
@property (readonly) WALocation *currentLocation;
//@property UIPageViewController *pageVC;

- (void)saveLocationsInDatabase;    // updates user defaults database
- (void)changedLocationAtIndex:(NSUInteger)index; //updates table view

@end
