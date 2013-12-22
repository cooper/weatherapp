//
//  WAWeatherController.m
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/28/13.
//  Copyright (c) 2013 Really Good. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "WAWeatherVC.h"
#import "WALocation.h"

@interface WAWeatherVC ()

@end

@implementation WAWeatherVC

#pragma mark - View controller

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor  = TABLE_COLOR;
    
    for (UILabel *label in @[self.temperature, self.conditionsLabel, self.locationTitle, self.coordinateLabel, self.fullLocationLabel, self.timeLabel]) {
        label.layer.shadowColor     = [UIColor blackColor].CGColor;
        label.layer.shadowOffset    = CGSizeMake(0, 0);
        label.layer.shadowRadius    = label == self.temperature ? 3.0 : 2.0;
        label.layer.shadowOpacity   = 1.0;
        label.layer.masksToBounds   = NO;
        label.layer.shouldRasterize = YES;
    }

    self.conditionsImageView.alpha = 0.8;
    [self update];
    
}

- (void)viewWillAppear:(BOOL)animated {
    //self.navigationController.navigationBar.tintColor    = BLUE_COLOR;]
    //self.navigationController.navigationBar.barTintColor = [UIColor clearColor];

    //[self.navigationController setNavigationBarHidden:YES animated:animated];
    //self.navigationController.interactivePopGestureRecognizer.delegate = self;
    [self update];
    
}

- (void)viewDidAppear:(BOOL)animated {

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Updates from WALocation

- (void)update {

    // in location.m, add two methods: beginLoading, finishLoading.
    // beginLoading will increase activity, set loading property, etc.
    // finishLoading will decrease activity, undo loading property, update the VC, etc.
    
    // info.
    self.locationTitle.text     = self.location.city;
    self.fullLocationLabel.text = self.location.fullName;
  //self.fullLocationLabel.text = FMT(@"%@, %@", self.location.city, self.location.region);
    self.coordinateLabel.text   = FMT(@"%f,%f", self.location.latitude, self.location.longitude);
    self.conditionsLabel.text   = self.location.conditions;
    
    // conditions icon.
    self.conditionsImageView.image = [UIImage imageNamed:FMT(@"icons/230/%@", self.location.conditionsImageName)];
    if (!self.conditionsImageView.image) self.conditionsImageView.image = self.location.conditionsImage;
    
    // temperature.
    if ([[DEFAULTS objectForKey:@"Temperature scale"] isEqualToString:@"Fahrenheit"])
        self.temperature.text = [NSString stringWithFormat:@"%.f", self.location.degreesF];
    else if ([[DEFAULTS objectForKey:@"Temperature scale"] isEqualToString:@"Celsius"])
        self.temperature.text = [NSString stringWithFormat:@"%.f", self.location.degreesC];
    else if ([[DEFAULTS objectForKey:@"Temperature scale"] isEqualToString:@"Kelvin"])
        self.temperature.text = [NSString stringWithFormat:@"%.f", self.location.degreesC + 273.15];

    // as of.
//    NSDate *now = [NSDate date];
//    NSDate *obv = self.location.observationsAsOf;
//    NSDateComponents *today    = [[NSCalendar currentCalendar] components:NSDayCalendarUnit fromDate:now];
//    NSDateComponents *obvDay   = [[NSCalendar currentCalendar] components:NSDayCalendarUnit fromDate:obv];
//    NSDateFormatterStyle style = [today day] == [obvDay day] ? NSDateFormatterNoStyle : NSDateFormatterShortStyle;
//    self.timeLabel.text = [NSDateFormatter localizedStringFromDate:self.location.observationsAsOf dateStyle:style timeStyle:NSDateFormatterLongStyle];
    self.timeLabel.text = self.location.observationTimeString;
    
    [self updateBackground];
}

- (void)updateBackground {
    
    if (!background) {
        background = [[UIImageView alloc] init];
        [self.view addSubview:background];
        [self.view sendSubviewToBack:background];
    }
    
    background.image = self.location.background;
    background.frame = self.view.bounds;

}

@end
