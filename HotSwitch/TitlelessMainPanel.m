//
//  TitlelessMainPanel.m
//  HotSwitch
//
//  Created by oniatsu on 2014/09/13.
//  Copyright (c) 2014年 oniatsu. All rights reserved.
//

#import "TitlelessMainPanel.h"

@implementation TitlelessMainPanel

- (BOOL)canBecomeKeyWindow {
    // because the window is borderless, we have to make it active
    return YES;
}

- (BOOL)canBecomeMainWindow {
    // because the window is borderless, we have to make it active
    return YES;
}

-(BOOL)isMovable
{
    return NO;
}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:bufferingType defer:flag];
    
    if ( self )
    {
        [self setStyleMask:NSBorderlessWindowMask];
        [self setOpaque:NO];
        [self setBackgroundColor:[NSColor clearColor]];
    }
    
    return self;
}

- (void) setContentView:(NSView *)aView
{
    aView.wantsLayer            = YES;
    aView.layer.frame           = aView.frame;
    aView.layer.cornerRadius    = 20.0;
    aView.layer.masksToBounds   = YES;
    
    [super setContentView:aView];
}

@end
