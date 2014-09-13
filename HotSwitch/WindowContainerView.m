//
//  WindowContainerView.m
//  HotSwitch
//
//  Created by oniatsu on 2014/09/23.
//  Copyright (c) 2014年 oniatsu. All rights reserved.
//

#import "WindowContainerView.h"

@implementation WindowContainerView

- (void)drawRect:(NSRect)dirtyRect
{
//    [super drawRect:dirtyRect];
    
//    [[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:1] set];
//    [[NSColor colorWithCalibratedRed:0.1 green:0.1 blue:0.1 alpha:0.85] set];
    [[NSColor colorWithCalibratedRed:0.3 green:0.3 blue:0.3 alpha:0.7] set];
    NSRectFill(dirtyRect);
}

@end
