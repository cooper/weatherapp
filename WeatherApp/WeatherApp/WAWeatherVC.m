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
    
    for (UILabel *label in @[self.temperature, self.conditionsLabel, self.locationTitle, self.coordinateLabel, self.fullLocationLabel]) {
        label.layer.shadowColor     = [UIColor blackColor].CGColor;
        label.layer.shadowOffset    = CGSizeMake(0, 0);
        label.layer.shadowRadius    = label == self.temperature ? 3.0 : 2.0;
        label.layer.shadowOpacity   = 1.0;
        label.layer.masksToBounds   = NO;
        label.layer.shouldRasterize = YES;
    }

    self.conditionsImageView.alpha = 0.8;

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

    
    // in order by priority. the first match wins.
    NSArray *backgrounds = @[
        @{
            @"name":        @"rainy",
            @"icon":        @"rain",
            @"day":         @[@"umbrella2"]
        },
        @{
            @"name":        @"overcast",
            @"conditions":  @"overcast",
            @"day":         @[@"overcast2", @"overcast"]
        },
        @{
            @"name":        @"smoke",
            @"conditions":  @"smoke",
            @"day":         @[@"smoke", @"smoke2"]
        },
        @{
            @"name":        @"cloudy",
            @"icon":        @"cloud",
            @"day":         @[@"clouds"]
        },
        @{
            @"name":        @"clear",
            @"icon":        @"clear",
            @"day":         @[@"clear", @"clear2"],
            @"night":       @[@"clear-night", @"clear-night3"]
        }
    ];

    
    // if the icon and conditions haven't changed, don't waste energy analyzing backgrounds.
    unsigned int i = 0; NSDictionary *selection;
    if ([currentBackgroundIcon isEqualToString:self.location.conditionsImageName] && [currentBackgroundConditions isEqualToString:self.location.conditions])
        NSLog(@"icon and conditions not changed");
    
    // find a background.
    else for (NSDictionary *bg in backgrounds) {
        BOOL matchesIcon = bg[@"icon"] && [self.location.conditionsImageName rangeOfString:bg[@"icon"] options:NSCaseInsensitiveSearch].location != NSNotFound;
        BOOL matchesConditions = bg[@"conditions"] && [self.location.conditions rangeOfString:bg[@"conditions"] options:NSCaseInsensitiveSearch].location != NSNotFound;
    
        // this is a match.
        if (matchesIcon || matchesConditions) {
        
            NSLog(@"%@ matches!", bg[@"name"]);
            
            // if it's night and backgrounds exist for such, prefer them.
            BOOL nightTime = NO;
            if (self.location.nightTime && bg[@"night"]) nightTime = YES;
            
            // here's our winning list.
            selection = @{
                @"index": @(i),
                @"name":  bg[@"name"],
                @"night": @(nightTime)
            };
            break;
            
        }
        
        i++;
    }
    
    // if the background category and time of day are same, nothing needs to be changed.
    NSString *chosenBackground;
    if ([currentBackgroundName isEqualToString:selection[@"name"]] && currentBackgroundTimeOfDay == [selection[@"night"] boolValue])
        NSLog(@"conditions/icon changed, but category and time of day still same");
    
    // a background group was selected.
    else if (selection) {
    
        unsigned int i      = [selection[@"index"] unsignedIntValue];
        BOOL nightTime      = [selection[@"night"] boolValue];
        NSString *timeOfDay = nightTime ? @"night" : @"day";

        
        NSString *storageName = FMT(@"%@-%@", selection[@"name"], timeOfDay);
        NSArray *choices      = backgrounds[i][timeOfDay];
        
        // fetch the background storage.
        NSMutableDictionary *bgStorage = [[DEFAULTS objectForKey:@"backgrounds"] mutableCopy];
        unsigned int useIndex = 0;
        
        // use the one after the last-used.
        if (bgStorage[storageName])
            useIndex = [bgStorage[storageName] unsignedIntValue] + 1;
        
        // we exceeded the array's limits; go back to the first.
        if (useIndex >= [choices count]) useIndex = 0;
        
        // here's the final winner.
        chosenBackground       = choices[useIndex];
        bgStorage[storageName] = @(useIndex);
        [DEFAULTS setObject:bgStorage forKey:@"backgrounds"];
        
        NSLog(@"chosen: %@", chosenBackground);
        
    }
    
    // finally apply the background.
    if (chosenBackground) {
    
        if (!background) {
            background = [[UIImageView alloc] init];
            [self.view addSubview:background];
            [self.view sendSubviewToBack:background];
        }
        
        background.image = [UIImage imageNamed:FMT(@"backgrounds/%@.jpg", chosenBackground)];
        background.frame = self.view.bounds;
        
        currentBackgroundName       = selection[@"name"];
        currentBackgroundIcon       = self.location.conditionsImageName;
        currentBackgroundConditions = self.location.conditions;
        currentBackgroundTimeOfDay  = [selection[@"night"] boolValue];
        
        NSLog(@"updating background to %@", chosenBackground);
        
    }

}

@end
