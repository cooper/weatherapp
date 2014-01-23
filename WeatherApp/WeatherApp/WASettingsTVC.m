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
        @[kTemperatureScaleSetting, @[
            kTemperatureScaleFahrenheit,
            kTemperatureScaleCelsius,
            kTemperatureScaleKelvin
        ]],
        @[kDistanceMeasureSetting, @[
            kDistanceMeasureMiles,
            kDistanceMeasureKilometers
        ]],
        @[kPercipitationMeasureSetting, @[
            kPercipitationMeasureInches,
            kPercipitationMeasureMilimeters
        ]]
    ];
    
    self.tableView.backgroundColor = TABLE_COLOR;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [settings count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [settings[section][1] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    NSString *sectionName = settings[indexPath.section][0];
    NSString *rowName     = settings[indexPath.section][1][indexPath.row];

    cell.textLabel.text = rowName;
    
    // this is the current value?
    if ([[DEFAULTS objectForKey:sectionName] isEqualToString:rowName])
        cell.accessoryType  = UITableViewCellAccessoryCheckmark;
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

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
    [cell setSelected:NO animated:YES];
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return settings[section][0];
}

@end
