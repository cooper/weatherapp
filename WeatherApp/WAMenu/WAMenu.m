//
//  WAMenu.m
//
//  Based on DIYMenu,
//  Created by Jonathan Beilin on 8/13/12.
//
//  Copyright (c) 2014 Mitchell Cooper.
//  Copyright (c) 2012 DIY. All rights reserved.
//

#import "WAMenu.h"
#import "WAMenuItem.h"

@interface WAMenu ()

@property BOOL      isActivated;
@property UIView    *shadingView;

@end

@implementation WAMenu

#pragma mark - Init

- (void)setup {
    CGRect frame = [UIScreen mainScreen].bounds;
    self.frame = frame;
    _menuItems = [NSMutableArray array];
    self.clipsToBounds = true;

    // Set up shadingview
    _shadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    self.shadingView.backgroundColor = [UIColor blackColor];
    self.shadingView.alpha = 0.0f;
    [self addSubview:self.shadingView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedBackground)];
    [self.shadingView addGestureRecognizer:tap];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) [self setup];
    return self;
}

#pragma mark - Show and Dismiss methods

- (void)showMenu {
    NSEnumerator *frontToBackWindows = [[[UIApplication sharedApplication]windows]reverseObjectEnumerator];
    for (UIWindow *window in frontToBackWindows) {
        if (window.windowLevel == UIWindowLevelNormal) {
            [window addSubview:self];
            break;
        }
    }
    
    //
    // Animate in items & darken background
    //
    
    [self.menuItems enumerateObjectsUsingBlock:^(WAMenuItem *item, NSUInteger idx, BOOL *stop) {
        item.transform = CGAffineTransformMakeTranslation(0, -ITEMHEIGHT * (idx + 2));
    }];
    
    [UIView animateWithDuration:0.22f delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self.menuItems enumerateObjectsUsingBlock:^(WAMenuItem *item, NSUInteger idx, BOOL *stop) {
            item.transform = CGAffineTransformMakeTranslation(0, 0);
        }];
        self.shadingView.alpha = 0.75f;
    } completion:nil];
    
    self.isActivated = true;
    
    // Delegate call
    if ([self.delegate respondsToSelector:@selector(menuActivated)]) {
        [self.delegate performSelectorOnMainThread:@selector(menuActivated) withObject:nil waitUntilDone:false];
    }
}

- (void)dismissMenu {
    // Animate out the items
    [UIView animateWithDuration:0.22f delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
        [self.menuItems enumerateObjectsUsingBlock:^(WAMenuItem *item, NSUInteger idx, BOOL *stop) {
            item.transform = CGAffineTransformMakeTranslation(0, (CGFloat) -ITEMHEIGHT * (idx + 2));
        }];
    } completion:nil];
    
    // Fade out the overlay window and remove self from it
    [UIView animateWithDuration:0.22 delay:0.0f options:UIViewAnimationOptionCurveLinear animations:^{
        self.shadingView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
    
    self.isActivated = false;
}

#pragma mark - UI

- (void)tappedBackground {
    [self dismissMenu];
    if ([self.delegate respondsToSelector:@selector(menuCancelled)]) {
        [self.delegate performSelectorOnMainThread:@selector(menuCancelled) withObject:nil waitUntilDone:false];
    }
}

- (void)menuAction:(NSString *)action {
    [self.delegate menuItemSelected:action];
    [self dismissMenu];
}

#pragma mark - Item management

- (CGRect)newItemFrame {
    UIApplication *application = [UIApplication sharedApplication];
    float padding = application.statusBarHidden ? 0 :
        MIN(application.statusBarFrame.size.height, application.statusBarFrame.size.width);
    NSUInteger itemCount = [self.menuItems count];
    return CGRectMake(0, padding + itemCount*ITEMHEIGHT, self.frame.size.height, ITEMHEIGHT);
}

- (void)addItem:(NSString *)name icon:(UIImage *)image color:(UIColor *)color font:(UIFont *)font {
    WAMenuItem *item = [[WAMenuItem alloc] initWithFrame:[self newItemFrame]];
    [item setName:name icon:image color:color font:font];
    item.layer.shouldRasterize = true;
    item.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    item.delegate = self;
    
    [self.menuItems addObject:item];
    [self addSubview:item];
}

- (void)clearMenu {
    [self.menuItems enumerateObjectsUsingBlock:^(WAMenuItem *item, NSUInteger idx, BOOL *stop) {
        [item removeFromSuperview];
    }];
    
    [self.menuItems removeAllObjects];
}

@end
