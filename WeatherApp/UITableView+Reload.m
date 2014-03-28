//
//  UITableViewController+Reload.m
//  Weather
//
//  Created by Mitchell Cooper on 3/22/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

#import "UITableView+Reload.h"

@implementation UITableView (Reload)

- (void)reloadData:(BOOL)animated
{
    [self reloadData];
    if (!animated) return;
    
    CATransition *animation = [CATransition animation];
    [animation setType:kCATransitionFade];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [animation setFillMode:kCAFillModeBoth];
    [animation setDuration:0.3];
    [[self layer] addAnimation:animation forKey:@"UITableViewReloadDataAnimationKey"];
}

@end
