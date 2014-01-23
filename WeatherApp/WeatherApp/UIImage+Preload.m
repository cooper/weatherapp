//
//  UIImage+Preload.m
//  Weather
//
//  Created by Mitchell Cooper on 1/23/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

#import "UIImage+Preload.h"

@implementation UIImage (Preload)

// preload an image.
- (UIImage *)preloadedImage {
    CGImageRef image = self.CGImage;
    
    size_t width  = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    
    CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef imageContext   = CGBitmapContextCreate(
        NULL, width, height, 8, width * 4, colourSpace,
        kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little
    );
    
    CGColorSpaceRelease(colourSpace);
    CGContextDrawImage(imageContext, CGRectMake(0, 0, width, height), image);
    CGImageRef outputImage = CGBitmapContextCreateImage(imageContext);
    
    UIImage *cachedImage = [UIImage imageWithCGImage:outputImage];
    
    CGImageRelease(outputImage);
    CGContextRelease(imageContext);
    
    return cachedImage;
}

@end
