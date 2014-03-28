//
//  WAWeatherVC.h
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/28/13.
//  Copyright (c) 2013-14 Mitchell Cooper. All rights reserved.
//

@interface WAWeatherVC : UIViewController {
    UIBarButtonItem *refreshButton;                         // the refresh button in navbar
    NSDate          *lastHourlyPreviewUpdate;               // time we last updated the hourly preview
}

@property IBOutlet UILabel *locationTitle;                  // label for city name
@property IBOutlet UILabel *temperature;                    // label for temperature
@property IBOutlet UILabel *conditionsLabel;                // label for conditions description
@property IBOutlet UILabel *feelsLikeLabel;                 // label for feels like temperature
@property IBOutlet UIImageView        *conditionsImageView; // 230x230pt conditions icon
@property IBOutlet NSLayoutConstraint *heightConstraint;    // constraint for everything minus navbar
@property IBOutlet UIView   *centeredView;                  // 416x320pt container to fit any iPhone
@property IBOutlet UIView   *hourlyContainer;               // view for hourly preview at bottom
@property (weak) WALocation *location;                      // weak reference to this view's location

- (instancetype)initWithLocation:(WALocation *)location;    // initialize with a location
- (void)update;                                             // update the displayed information

@end
