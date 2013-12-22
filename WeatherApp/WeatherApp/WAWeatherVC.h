//
//  WAWeatherController.h
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/28/13.
//  Copyright (c) 2013 Really Good. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface WAWeatherVC : UIViewController <UIGestureRecognizerDelegate> {
    UIBarButtonItem *refreshButton;
    UIImageView *background;
    NSString *currentBackgroundName;
    NSString *currentBackgroundIcon;
    NSString *currentBackgroundConditions;
    BOOL currentBackgroundTimeOfDay;
}

@property IBOutlet UILabel *locationTitle;
@property IBOutlet UILabel *temperature;
@property IBOutlet UILabel *fullLocationLabel;
@property IBOutlet UILabel *coordinateLabel;
@property IBOutlet UILabel *conditionsLabel;
@property IBOutlet UILabel *timeLabel;
@property IBOutlet UIImageView *conditionsImageView;
@property (weak) WALocation *location;

// these methods are for communication between the location object and
// the interface. this approach makes it very easy to make interface
// changes by keeping all interface code within the view controller
// and all functionality code within the location object.

- (void)update;

@end
