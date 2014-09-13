//
//  KeyBindTableView.m
//  HotSwitch
//
//  Created by oniatsu on 2014/09/13.
//  Copyright (c) 2014年 oniatsu. All rights reserved.
//

#import "KeyBindTableView.h"
#import "AppDelegate.h"

@implementation KeyBindTableView
{
    BOOL isRegistrationMode;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        
        isRegistrationMode = NO;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    [self setRowHeight:23];
    [self setFocusRingType:NSFocusRingTypeNone];
    
    [self setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
}

- (void)drawRow:(NSInteger)row clipRect:(NSRect)clipRect
{
    NSInteger selectedRowIndex = [self selectedRow];
    if (row == selectedRowIndex) {
        if (isRegistrationMode) {
            [[NSColor colorWithCalibratedRed:0.4 green:0.4 blue:0.2 alpha:1.0] set];
        } else {
            [[NSColor colorWithCalibratedWhite:0.3 alpha:1.0] setFill];
        }
    } else {
        [[NSColor colorWithCalibratedWhite:1.0 alpha:0.0] setFill];
    }
    NSRectFill([self rectOfRow:row]);
    
    [super drawRow:row clipRect:clipRect];
}

- (void)keyDown:(NSEvent *)theEvent
{
    [(AppDelegate*) [[NSApplication sharedApplication] delegate] keyDownAtTable:theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
    
    [(AppDelegate*) [[NSApplication sharedApplication] delegate] mouseDownAtTable:theEvent];
}

- (void)setRegistrationMode:(BOOL)flag
{
    isRegistrationMode = flag;
}

@end
