//
//  PaddingView.m
//  HotSwitch
//
//  Created by oniatsunishi on 2014/09/25.
//  Copyright (c) 2014年 oniatsu. All rights reserved.
//

#import "PaddingView.h"

@implementation PaddingView

- (void)drawRect:(NSRect)dirtyRect {
//    [super drawRect:dirtyRect];
    
    // Drawing code here.
    
    self.wantsLayer = YES;
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = 10.0;
    
    [[NSColor colorWithCalibratedRed:0.1 green:0.1 blue:0.1 alpha:0.8] set];
    NSRectFill(dirtyRect);
}

@end
