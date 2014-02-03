//
//  UIImage+Preload.m
//  Weather
//
//  Created by Mitchell Cooper on 1/23/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

#import "UIImage+Preload.h"

@implementation UIImage (Preload)

CGImageRef preload_image(CGImageRef image) {
    
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
    CGContextRelease(imageContext);
    
    return outputImage;
}

// preload an image.
- (UIImage *)preloadedImage {
    CGImageRef image = preload_image(self.CGImage);
    UIImage *uiimage = [UIImage imageWithCGImage:image];
    CGImageRelease(image);
    return uiimage;
}

@end
