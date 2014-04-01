//
//  WASettingsTVC.m
//  WeatherApp
//
//  Created by Mitchell Cooper on 11/3/13.
//  Copyright (c) 2013-14 Mitchell Cooper. All rights reserved.
//

#import "WASettingsTVC.h"

@implementation WASettingsTVC

#pragma mark - Table view controller

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = @"Settings";
    settings = @[
    
        // string selection settings.
    
        @[kTemperatureScaleSetting, @[
            kTemperatureScaleFahrenheit,
            kTemperatureScaleCelsius,
            kTemperatureScaleKelvin
        ]],
        @[kDistanceMeasureSetting, @[
            kDistanceMeasureMiles,
            kDistanceMeasureKilometers
        ]],
        @[kPrecipitationMeasureSetting, @[
            kPrecipitationMeasureInches,
            kPrecipitationMeasureMilimeters
        ]],
        @[kPressureMeasureSetting, @[
            kPressureMeasureInchHg,
            kPressureMeasureMillibar
        ]],
        @[kTimeZoneSetting, @[
            kTimeZoneRemote,
            kTimeZoneLocal
        ]],
        
        // boolean settings.
        
        @[
            kEnableBackgroundSetting,
            kEnableHourlyPreviewSetting
        ],
        
        // credit cells.
        
        @[
            @[@"Icons",                 @"Mitchell Cooper"      ],
            @[@"Other images",          @"Public domain"        ],
            @[@"Weather data",          @"WeatherUnderground"   ],
            @[@"Flag icons",            @"www.icondrawer.com"   ],
            @""
        ]
        
    ];
    
    self.tableView.backgroundColor = TABLE_COLOR;
}

// update the time of last potential settings change.
- (void)viewWillAppear:(BOOL)animated {
    appDelegate.lastSettingsChange = [NSDate date];
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [settings count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section < [settings count] - 2) return [settings[section][1] count];
    return [settings[section] count];
}

// we don't reuse any cells here. they are so basic, and there are so few
// that there would honestly be no actual advantage to reusal.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    
    NSString *sectionName, *rowName;
    
    // string option.
    if (indexPath.section < [settings count] - 2) {
        sectionName = settings[indexPath.section][0];
        rowName     = settings[indexPath.section][1][indexPath.row];
        
        // this is the current value?
        if ([[DEFAULTS objectForKey:sectionName] isEqualToString:rowName])
            cell.accessoryType  = UITableViewCellAccessoryCheckmark;
        
        cell.selectedBackgroundView = [UIView new];
        cell.selectedBackgroundView.backgroundColor = CELL_SEL_COLOR;
    }
    
    // boolean option.
    else if (indexPath.section < [settings count] - 1) {
        rowName        = settings[indexPath.section][indexPath.row];
        UISwitch *sw   = [UISwitch new];
        sw.on          = SETTING(rowName);
        sw.tag         = indexPath.row; // used below to get settings key
        sw.onTintColor = BLUE_COLOR;
        [sw addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = sw;
    }

    // credits.
    else {
    
        // wunderground icon.
        if (settings[indexPath.section][indexPath.row] == [settings[indexPath.section] lastObject]) {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"wunderground"]];
            imageView.center = [cell.contentView convertPoint:cell.contentView.center fromView:cell.contentView.superview];
            [cell.contentView addSubview:imageView];
        }
        
        // other credit.
        else {
            rowName = settings[indexPath.section][indexPath.row][0];
            cell.detailTextLabel.text = settings[indexPath.section][indexPath.row][1];
        }
        
    }

    cell.textLabel.text = rowName;
    return cell;
}

// only highlight the selection options.
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < [settings count] - 2) return YES;
    return NO;
}

// selected a selection option.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *sectionName = settings[indexPath.section][0];
    NSString *rowName     = settings[indexPath.section][1][indexPath.row];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];

    // remove checkmarks from any rows that currently have one in this section.
    for (unsigned int i = 0; i <= [settings[indexPath.section] count]; i++) {
        UITableViewCell *c = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
        c.accessoryType = UITableViewCellAccessoryNone;
    }
    
    // add checkmark to this row.
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    // save changes.
    [DEFAULTS setObject:rowName forKey:sectionName];
    
    // unhighlight row.
    // this fixes the issue where it would stick after scrolling back to it.
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == [settings count] - 2) return @"Options";
    if (section == [settings count] - 1) return @"Credits";
    return settings[section][0];
}

#pragma mark - Interface actions

- (void)valueChanged:(UISwitch *)sw {
    NSString *setting = settings[ [settings count] - 2 ][sw.tag];
    [DEFAULTS setBool:sw.on forKey:setting];
}

@end
