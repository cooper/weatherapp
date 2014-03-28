//
//  WALocationself.m
//  Weather
//
//  Created by Mitchell Cooper on 3/26/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

#import "WALocationCell.h"
#import "WALocation.h"

@implementation WALocationCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) [self setup];
    return self;
}

- (void)setup {
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    
    // background view.
    UIImageView *cellBg = [UIImageView new];
    cellBg.frame        = self.bounds;
    self.backgroundView = cellBg;

    // icon view.
    self.iconView = [[UIImageView alloc] initWithFrame:CGRectMake(screenWidth - 60, 25, 50, 50)];
    self.iconView.layer.shadowColor         = DARK_BLUE_COLOR.CGColor;
    self.iconView.layer.shadowOffset        = CGSizeMake(0, 0);
    self.iconView.layer.shadowRadius        = 1.0;
    self.iconView.layer.shadowOpacity       = 1.0;
    self.iconView.layer.shouldRasterize     = YES;
    [self addSubview:self.iconView];
    
    // labels.
    self.locationLabel    = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, screenWidth, 40)];
    self.conditionsLabel  = [[UILabel alloc] initWithFrame:CGRectMake(0,  50, 0,   40)]; // x and w TBD
    self.temperatureLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 50, 100, 40)];
    self.locationLabel.font    = [UIFont systemFontOfSize:30];
    self.conditionsLabel.font  = [UIFont systemFontOfSize:25];
    self.temperatureLabel.font = [UIFont boldSystemFontOfSize:35];
    
    // selected translucent blue tint.
    self.selectedBackgroundView = [UIView new];
    self.selectedBackgroundView.backgroundColor = [UIColor colorWithRed:0 green:150./255. blue:1 alpha:0.3];
    self.backgroundColor = [UIColor clearColor];
    
    // text shadows.
    for (UILabel *label in @[self.locationLabel, self.temperatureLabel, self.conditionsLabel]) {
        label.adjustsFontSizeToFitWidth = YES;
        label.layer.shadowColor         = DARK_BLUE_COLOR.CGColor;
        label.layer.shadowOffset        = CGSizeMake(0, 0.4);
        label.layer.shadowRadius        = 1.5;
        label.layer.shadowOpacity       = 1.0;
        label.layer.shouldRasterize     = YES;
        label.textColor                 = [UIColor whiteColor];
        [self addSubview:label];
    }
    
    // activity indicator.
    self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.indicator.frame = self.iconView.frame;
    [self addSubview:self.indicator];

}

- (void)setLocation:(WALocation *)location {
    UIImageView *backgroundView = (UIImageView *)self.backgroundView;
    
    // if the initial loading is not complete, remove stuff.
    if (!location.initialLoadingComplete) {
        backgroundView.image        = nil;
        self.conditionsLabel.text   =
        self.temperatureLabel.text  =
        self.locationLabel.text     = nil;
    }

    // start the indicator.
    // hide the shadow when it's loading.
    // otherwise, the activity indicator would have a shadow.
    if (location.loading) {
        self.iconView.layer.shadowColor = [UIColor clearColor].CGColor;
        [self.indicator startAnimating];
    }
    
    // hide the indicator and replace the shadow.
    else {
        self.iconView.layer.shadowColor = DARK_BLUE_COLOR.CGColor;
        [self.indicator stopAnimating];
    }

    // location info.
    NSString *city   = [location.city   length] ? location.city   : @"";
    NSString *region = [location.region length] ? location.region : ([location.longName length] ? location.longName : @"Locating...");
    if (self.isFakeLocation) {
        city   = location.conditions;
        region = @"";
    }
    NSString *both = FMT(@"%@ %@", city, region);

    // make the city name bold.
    NSMutableAttributedString *name = [[NSMutableAttributedString alloc] initWithString:both attributes:nil];
    [name addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:30] range:NSMakeRange(0, [city length])];
    
    // make the region name smaller.
    [name setAttributes:@{
        NSFontAttributeName:            [UIFont systemFontOfSize:15],
        //NSForegroundColorAttributeName: [UIColor grayColor]
    } range:NSMakeRange([city length] + 1, [region length])];
    
    self.locationLabel.attributedText = name;
    self.iconView.image  = OR(location.conditionsImage, [UIImage imageNamed:@"icons/dummy"]);
    backgroundView.image = location.cellBackground;


    if (location.highC != TEMP_NONE)
        self.temperatureLabel.text = FMT(@"▲ %@ ▼ %@", location.highTemp, location.temperature);
    else if (location.degreesC != TEMP_NONE)
        self.temperatureLabel.text = FMT(@"%@%@", location.temperature, location.tempUnit);
    
    [self.temperatureLabel sizeToFit];
    
    CGFloat offset = self.temperatureLabel.frame.origin.x + self.temperatureLabel.frame.size.width + 10;
    self.conditionsLabel.frame = CGRectMake(
        offset,
        self.conditionsLabel.frame.origin.y,
        [UIScreen mainScreen].bounds.size.width - offset,
        self.conditionsLabel.frame.size.height
    );
    
    self.conditionsLabel.text = self.isFakeLocation ? @"" : location.conditions;


}

@end
