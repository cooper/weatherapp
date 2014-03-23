//
//  WAWeatherVC.h
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/28/13.
//  Copyright (c) 2013-14 Mitchell Cooper. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface WAWeatherVC : UIViewController {
    UIBarButtonItem *refreshButton;
}

@property IBOutlet UILabel *locationTitle;
@property IBOutlet UILabel *temperature;
@property IBOutlet UILabel *regionLabel;
@property IBOutlet UILabel *coordinateLabel;
@property IBOutlet UILabel *conditionsLabel;
@property IBOutlet UILabel *feelsLikeLabel;
@property IBOutlet UIImageView *conditionsImageView;

@property (weak) WALocation *location;

// these methods are for communication between the location object and
// the interface. this approach makes it very easy to make interface
// changes by keeping all interface code within the view controller
// and all functionality code within the location object.

- (id)initWithLocation:(WALocation *)location;
- (void)update;

@end
