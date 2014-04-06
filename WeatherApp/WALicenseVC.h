//
//  WALicenseVC.h
//  Weather
//
//  Created by Mitchell Cooper on 4/1/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

@interface WALicenseVC : UIViewController {
    NSDictionary *licenses;
    NSString     *licenseKey;
}

- (instancetype)initWithLicense:(NSString *)key;

@end
