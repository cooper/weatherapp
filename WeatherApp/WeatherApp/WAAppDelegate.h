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

#define IS_IPHONE   ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
#define IS_IPAD     ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)


#define WU_API_KEY @"ffd9e1544413efef"
#define GEO_LOOKUP_USERNAME @"cooper"

#define LLLL_BLUE_COLOR [UIColor colorWithRed:20.0f/255.0f green:200.0f/255.0f blue:255.0f/255.0f alpha:1.0f]
#define LLL_BLUE_COLOR  [UIColor colorWithRed:0.0f/255.0f green:180.0f/255.0f blue:255.0f/255.0f alpha:1.0f]
#define LL_BLUE_COLOR   [UIColor colorWithRed:0.0f/255.0f green:170.0f/255.0f blue:255.0f/255.0f alpha:1.0f]
#define L_BLUE_COLOR    [UIColor colorWithRed:0.0f/255.0f green:160.0f/255.0f blue:255.0f/255.0f alpha:1.0f]
#define BLUE_COLOR      [UIColor colorWithRed:0.0f/255.0f green:150.0f/255.0f blue:255.0f/255.0f alpha:1.0f]

#define FMT(str, ...) [NSString stringWithFormat:str, ##__VA_ARGS__]
#define L(str) NSLocalizedString(str, nil)
#define URL_ESC(str) [str stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
#define OR(this, otherwise) (this ? this : otherwise)
typedef void(^WACallback)(void);

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
