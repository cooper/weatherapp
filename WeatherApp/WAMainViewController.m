//
//  WAMainViewController.m
//  WeatherApp
//
//  Created by Mitchell Cooper on 10/28/13.
//  Copyright (c) 2013 Really Good. All rights reserved.
//

#import "WAMainViewController.h"

@interface WAMainViewController () {
    NSMutableArray *colors;
}

@end

@implementation WAMainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        colors = [@[
            [UIColor blackColor],
            [UIColor redColor],
            [UIColor blueColor],
            [UIColor brownColor],
            [UIColor yellowColor],
            [UIColor greenColor],
            [UIColor grayColor],
            [UIColor purpleColor]
        ] mutableCopy];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)buttonTapped:(id)sender {
    UIColor *color = [colors firstObject];
    [colors removeObjectAtIndex:0];
    [colors addObject:color];
    self.view.backgroundColor = color;
    
    NSLog(@"tapped! %@", color);

}

@end
