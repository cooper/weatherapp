//
//  WAConditionDetailTVCViewController.m
//  Weather
//
//  Created by Mitchell Cooper on 1/22/14.
//  Copyright (c) 2014 Really Good. All rights reserved.
//

#import "WAConditionDetailTVC.h"
#import "WALocation.h"
#import "WALocationListTVC.h"
#import "WAPageViewController.h"

@interface WAConditionDetailTVC ()

@end

@implementation WAConditionDetailTVC

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.navigationItem.title = @"Details";
    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:self.location.background];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorInset = UIEdgeInsetsZero;

    currentConditions    = [self detailsForLocation:self.location];
    forecastedConditions = [self forecastForLocation:self.location];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSArray *)detailsForLocation:(WALocation *)location {
    NSMutableArray *a = [NSMutableArray array];
    NSDictionary *r   = location.response;
    
    // temperatures.
    [a addObjectsFromArray:@[
        @[@"Temperature", FMT(@"%@ %@", location.temperature, location.tempUnit)],
        @[@"Feels like",  FMT(@"%@ %@", location.feelsLike,   location.tempUnit)],
        @[@"Dew point",   FMT(@"%@ %@", location.dewPoint,    location.tempUnit)]
    ]];
    
    if (location.heatIndexF)
        [a addObject:@[@"Heat index", FMT(@"%@%@", location.heatIndex, location.tempUnit)]];
    
    // precipitation.
    if (SETTING_IS(kPercipitationMeasureSetting, kPercipitationMeasureInches)) [a addObjectsFromArray:@[
        @[@"Precip. today",   FMT(@"%@ in", r[@"precip_today_in"])],
        @[@"Precip. in hour", FMT(@"%@ mm", r[@"precip_1hr_in"])]
    ]];
    else [a addObjectsFromArray:@[
        @[@"Precip. today",   FMT(@"%@ mm", r[@"precip_today_metric"])],
        @[@"Precip. in hour", FMT(@"%@ mm", r[@"precip_1hr_metric"])]
    ]];
    
    [a addObjectsFromArray:@[
        @[@"Pressure", FMT(@"%@ mb / %@ in", r[@"pressure_mb"], r[@"pressure_in"])],
        @[@"Humidity", r[@"relative_humidity"]]
        //@[@"Summary",  r[@"weather"]]
    ]];
    
    if (SETTING_IS(kDistanceMeasureSetting, kDistanceMeasureMiles)) [a addObjectsFromArray:@[
        @[@"Wind speed", FMT(@"%@ mph", r[@"wind_mph"])],
        @[@"Wind direction", FMT(@"%@ %@º", r[@"wind_dir"], r[@"wind_degrees"])],
        @[@"Visibility", FMT(@"%@ mi",  r[@"visibility_mi"])]
    ]];
    else [a addObjectsFromArray:@[
        @[@"Wind speed", FMT(@"%@ km/hr", r[@"wind_kph"])],
        @[@"Wind direction", FMT(@"%@ %@º", r[@"wind_dir"], r[@"wind_degrees"])],
        @[@"Visibility", FMT(@"%@ km",   r[@"visibility_mi"])]
    ]];
    
    return a;
}

- (NSArray *)forecastForLocation:(WALocation *)location {
    NSMutableArray *a = [NSMutableArray array];
    for (NSUInteger i = 0; i < [location.forecast count]; i ++)
        [a addObject:[self forecastForDay:location.forecast[i] text:location.textForecast[i]]];
    return a;
}

- (NSArray *)forecastForDay:(NSDictionary *)f text:(NSDictionary *)t {
    NSMutableArray *a    = [NSMutableArray array];
    WALocation *location = [[WALocation alloc] init];
    location.loading     = NO;
    location.initialLoadingComplete = YES;
    
    location.degreesC   = [f[@"high"][@"celsius"]    floatValue];
    location.degreesF   = [f[@"high"][@"fahrenheit"] floatValue];
    location.feelsLikeC = [f[@"low"][@"celsius"]     floatValue];
    location.feelsLikeF = [f[@"low"][@"fahrenheit"]  floatValue];
    
    location.city       = f[@"date"][@"weekday"];
    location.region     = FMT(@"%@ %@", f[@"date"][@"monthname_short"], f[@"date"][@"day"]);
    location.conditions = f[@"conditions"];
    location.conditionsAsOf = [NSDate date];
    
    location.response = @{
        @"icon":        f[@"icon"],
        @"icon_url":    f[@"icon_url"]
    };
    [location fetchIcon];
    
    NSLog(@"FETCHED: %@", location.conditionsImageName);
    [location updateBackgroundBoth:NO];
    
    [a addObjectsFromArray:@[
        @[@"High temperature", FMT(@"%@ %@", location.temperature, location.tempUnit)],
        @[@"Low temperature",  FMT(@"%@ %@", location.feelsLike,   location.tempUnit)]
    ]];
    
    NSLog(@"%@", location.userDefaultsDict);
    
    if (SETTING_IS(kTemperatureScaleSetting, kTemperatureScaleFahrenheit))
        [a addObject:@[t[@"fcttext"], @""]];
    else
        [a addObject:@[t[@"fcttext_metric"], @""]];
    
    return @[location, a];
}

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
    footer.textLabel.textColor          = [UIColor whiteColor];
    footer.contentView.backgroundColor  = [UIColor colorWithPatternImage:[UIImage imageNamed:@"navbar.png"]];
    footer.textLabel.textAlignment      = NSTextAlignmentLeft;
}

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [self.location.forecast count] + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (!section) return [currentConditions count];
    
    return [forecastedConditions[section - 1] count] + 2; // plus header and footer
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath.row) return 100;
    
    if (indexPath.section && indexPath.row > [forecastedConditions[indexPath.section - 1] count])
        return 150;
    
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    // generic base cell.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) cell       = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    cell.backgroundColor  = [UIColor clearColor];
    cell.textLabel.textColor       = [UIColor whiteColor];
    cell.detailTextLabel.textColor = [UIColor whiteColor];
    cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"navbar.png"]];
    
    // current conditions.
    if (!indexPath.section) {
    
        // show the location cell for this location.
        if (!indexPath.row) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"location"];
            [WALocationListTVC applyWeatherInfo:self.location toCell:cell];
            cell.backgroundView = nil;
            return cell;
        }
    
        // detail for current conditions.
        cell.textLabel.text = currentConditions[indexPath.row - 1][0];
        cell.detailTextLabel.text = currentConditions[indexPath.row - 1][1];
        return cell;
        
    }
    
    // artificial location row of a future day.
    if (!indexPath.row) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"location"];
        WALocation *location = forecastedConditions[indexPath.section - 1][0];
        [WALocationListTVC applyWeatherInfo:location toCell:cell];
        return cell;
    }
    
    // detail label on a forecast.
    cell.textLabel.text          = forecastedConditions[indexPath.section - 1][1][indexPath.row - 1][0];
    cell.detailTextLabel.text    = forecastedConditions[indexPath.section - 1][1][indexPath.row - 1][1];
    cell.textLabel.numberOfLines = 0;
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
