//
//  WAMenuItem.m
//
//  Based on DIYMenu,
//  Created by Jonathan Beilin on 8/13/12.
//
//  Copyright (c) 2014 Mitchell Cooper.
//  Copyright (c) 2012 DIY. All rights reserved.
//

#import "WAMenuItem.h"

@implementation WAMenuItem

#pragma mark - Init & Setup

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _delegate = nil;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.autoresizesSubviews = true;
        
        _shadingView = [[UIView alloc] initWithFrame:self.bounds];
        self.shadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.shadingView.backgroundColor = [UIColor blackColor];
        self.shadingView.userInteractionEnabled = false;
        self.shadingView.alpha = 0.0f;
        [self addSubview:self.shadingView];
        
        _menuPosition = CGPointMake(frame.origin.x, frame.origin.y);
    }
    return self;
}

- (void)setName:(NSString *)name color:(UIColor *)color font:(UIFont *)font {
    CGFloat x = ICONPADDING + ICONSIZE + ITEMPADDING;
    CGRect labelFrame = CGRectMake(x, 0, self.frame.size.width - x, ITEMHEIGHT);
    _name = [[UILabel alloc] initWithFrame:labelFrame];
    self.name.backgroundColor = [UIColor clearColor];
    self.name.textColor = [UIColor whiteColor];
    self.name.font = font;
    self.name.text = name;
    [self addSubview:self.name];
    
    self.backgroundColor = color;
    
    _icon = nil;
}

- (void)setName:(NSString *)name icon:(UIImage *)image color:(UIColor *)color font:(UIFont *)font {
    [self setName:name color:color font:font];
    
    if (image != nil) {
        _icon = [[UIImageView alloc] initWithImage:image];
        CGFloat y = (ITEMHEIGHT - ICONSIZE) / 2.;
        self.icon.frame = CGRectMake(ICONPADDING, y, ICONSIZE, ICONSIZE);
        self.icon.tag   = 10;
        [self addSubview:self.icon];
    }
    else {
        _icon = nil;
    }
}

#pragma mark - Drawing

- (void)depictSelected {
    if (!self.isSelected) {
        self.shadingView.alpha = 0.5f;
        [self bringSubviewToFront:self.shadingView];
        self.isSelected = true;
    }
}

- (void)depictUnselected {
    if (self.isSelected) {
        self.shadingView.alpha = 0.0f;
        self.isSelected = false;
    }
}

#pragma mark - Touching

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    [self depictSelected];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];

    CGPoint location = [[touches anyObject] locationInView:self];
    if (CGRectContainsPoint(self.bounds, location)) {
        [self depictSelected];
    }
    else {
        [self depictUnselected];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    
    [self depictUnselected];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    
    [self depictUnselected];
    
    // Call delegate if touch ended in view
    CGPoint location = [[touches anyObject] locationInView:self];
    if (CGRectContainsPoint(self.bounds, location)) {
        [self.delegate menuAction:self.name.text];
    }
}

@end
