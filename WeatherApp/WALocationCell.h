//
//  WALocationCell.h
//  Weather
//
//  Created by Mitchell Cooper on 3/26/14.
//  Copyright (c) 2014 Really Good. All rights reserved.
//

@interface WALocationCell : UITableViewCell

@property UILabel *temperatureLabel;
@property UILabel *conditionsLabel;
@property UILabel *locationLabel;
@property UIImageView *iconView;
@property UIActivityIndicatorView *indicator;

@property BOOL isFakeLocation;

- (void)setLocation:(WALocation *)location;

@end
