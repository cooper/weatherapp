//
//  WALicenseVC.m
//  Weather
//
//  Created by Mitchell Cooper on 4/1/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

#import "WALicenseVC.h"

@implementation WALicenseVC

- (instancetype)initWithLicense:(NSString *)key {
    self = [super initWithNibName:nil bundle:nil];
    if (self) licenseKey = key;
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"Credits";
    
    // load licenses from file.
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Licenses" ofType:@"plist"];
    licenses       = [NSDictionary dictionaryWithContentsOfFile:path];
    
    // create a scrollable text view that is not editable.
    CGSize size = self.view.frame.size;
    UITextView *textView        = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    textView.autoresizingMask   = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    textView.editable           = NO;
    textView.font               = [UIFont systemFontOfSize:16];
    textView.textAlignment      = NSTextAlignmentJustified;
    textView.text               = licenses[licenseKey];
    textView.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10);
    [self.view addSubview:textView];
    
}



@end
