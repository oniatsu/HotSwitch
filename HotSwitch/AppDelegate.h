//
//  AppDelegate.h
//  HotSwitch
//
//  Created by oniatsu on 2014/09/13.
//  Copyright (c) 2014年 oniatsu. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern CGError SLPSPostEventRecordTo(ProcessSerialNumber *psn, uint8_t *bytes);

@class MASShortcutView;
@class PaddingView;
@class KeyBindTableView;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (unsafe_unretained) IBOutlet NSPanel *panel;
@property (weak) IBOutlet PaddingView *padding;
@property (weak) IBOutlet NSScrollView *scrollView;
@property (weak) IBOutlet KeyBindTableView *table;

@property (weak) IBOutlet NSArrayController *arrayController;

@property (weak) IBOutlet NSMenu *statusMenu;

@property (weak) IBOutlet NSWindow *preferenceWindow;
@property (weak) IBOutlet MASShortcutView *shortcutView;

@property (nonatomic) BOOL isStartupEnabled;
@property (nonatomic) BOOL isHotKeyEnabled;
@property (nonatomic) BOOL isReplaceCmdTabEnabled;

@property (nonatomic) BOOL isKeyRegisteringMode;
@property (nonatomic) NSMutableArray *windowInfoArray;
@property (nonatomic) NSMutableArray *lastAllWindowInfoArray;
@property (nonatomic) NSMutableArray *allShowingWinKey;
@property (nonatomic) NSStatusItem *statusItem;

- (void)deactivatePanel;
- (void)keyDownAtTable:(NSEvent *)theEvent;
- (void)mouseDownAtTable:(NSEvent *)theEvent;
- (IBAction)openPreferences:(id)sender;
- (IBAction)openAbout:(id)sender;
- (IBAction)openHelp:(id)sender;
- (IBAction)openPanel:(id)sender;

@end
