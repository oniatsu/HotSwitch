//
//  AppDelegate.m
//  HotSwitch
//
//  Created by oniatsu on 2014/09/13.
//  Copyright (c) 2014年 oniatsu. All rights reserved.
//

#import "AppDelegate.h"
#import "WindowInfoModel.h"
#import "MASShortcut.h"
#import "MASShortcutView+UserDefaults.h"
#import "MASShortcut+UserDefaults.h"
#import "MASShortcut+Monitoring.h"
#import "PaddingView.h"
#import "KeyBindTableView.h"

@implementation AppDelegate
{
    CGFloat defaultPanelX;
    CGFloat defaultPanelY;
    CGFloat defaultPanelWidth;
    CGFloat defaultPanelHeight;
    
    CGFloat defaultPaddingX;
    CGFloat defaultPaddingY;
    CGFloat defaultPaddingWidth;
    CGFloat defaultPaddingHeight;
    
    CGFloat defaultScrollViewX;
    CGFloat defaultScrollViewY;
    CGFloat defaultScrollViewWidth;
    CGFloat defaultScrollViewHeight;
    
    CGFloat defaultTableHeight;
    
    CFMachPortRef      eventTap;
    CGEventMask        eventMask;
    CFRunLoopSourceRef runLoopSource;
}

// Preference key
NSString *const kPreferenceInitialization = @"Initialization";
NSString *const kPreferenceGlobalShortcut = @"GlobalShortcut";
NSString *const kPreferenceGlobalShortcutEnabled = @"GlobalShortcutEnabled";
NSString *const kPreferenceReplaceCmdTabEnabled = @"ReplaceCmdTabEnabled";
NSString *const kPreferenceWinKey = @"WinKey";

// URL
NSString *const kHotSwitchWebPageURI = @"http://oniatsu.github.io/HotSwitch/";

// Message
NSString *const kRegistrationMessage = @">> Input a key to be registerd <<";

// File name
NSString *const kMenuAppIconName = @"menu_icon_16";

#pragma mark - app events

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    [self initializeVariables];

    [self resetWindowInfoAndViewSize];
    
    [self setupStatusMenu];
    
    [self checkAccessibility];
    
    [self initializeHotkey];
    
    [self initializeFirstExecution];
    
    // For test
    //    [self executeHotkey];
}

#pragma mark - test

- (void)debugByLeftArrow
{
//    NSLog(@"debug - left");
}

- (void)debugByRightArrow
{
//    NSLog(@"debug - right");
}

#pragma mark - actions

- (IBAction)openPreferences:(id)sender {
    [self.preferenceWindow makeKeyAndOrderFront:sender];
    [[NSApplication sharedApplication] activateIgnoringOtherApps : YES];
    
    [self deactivatePanel];
}

- (IBAction)openAbout:(id)sender {
    [[NSApplication sharedApplication] orderFrontStandardAboutPanel:self] ;
    [[NSApplication sharedApplication] activateIgnoringOtherApps : YES];
    
    [self deactivatePanel];
}

- (IBAction)openHelp:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kHotSwitchWebPageURI]];
}

#pragma mark - user events

- (void)keyDownAtTable:(NSEvent *)theEvent
{
    unichar unicodeKey = [[theEvent characters] characterAtIndex:0];
    NSInteger keyCode = [theEvent keyCode];
//    NSLog(@"unicodeKey: %hu", unicodeKey);
//    NSLog(@"keyCode: %@", [NSString stringWithFormat:@"%lX", (long)keyCode]);
    
    switch (keyCode) {
        case kVK_LeftArrow:
            [self debugByLeftArrow];
            break;
        case kVK_RightArrow:
            [self debugByRightArrow];
            break;
    }
    
    if (self.isKeyRegisteringMode) { // on the registration mode
        if ([self isRegisterableKey:keyCode unicodeKey:unicodeKey]) {
            [self registerWinKey:[self keyStringByKeyCode:keyCode unicodeKey:unicodeKey]];
            [self endKeyRegisteringMode];
        } else {
            switch (keyCode) {
                case kVK_Space:
                    [self endKeyRegisteringMode];
                    break;
                case kVK_Delete:
                    [self deleteSelectedWinKey];
                    [self endKeyRegisteringMode];
                    break;
                case kVK_DownArrow:
                    break;
                case kVK_UpArrow:
                    break;
                case kVK_Tab:
                    break;
                case kVK_Return:
                case kVK_Escape:
                    [self endKeyRegisteringMode];
                    break;
                default:
                    break;
            }
        }
    } else { // on the normal mode
        if ([self isRegisterableKey:keyCode unicodeKey:unicodeKey]) {
            if ([self isShowingWinKey:[self keyStringByKeyCode:keyCode unicodeKey:unicodeKey]]) {
                [self activateSelectedWindowByKey:[self keyStringByKeyCode:keyCode unicodeKey:unicodeKey]];
                [self resetWindowInfoAndViewSize];
                [self deactivatePanel];
            }
        } else {
            switch (keyCode) {
                case kVK_Space:
                    [self startKeyRegisteringMode];
                    break;
                case kVK_Delete:
                    [self deleteSelectedWinKey];
                    break;
                case kVK_DownArrow:
                    // Down
                    [self selectNextRow];
                    break;
                case kVK_UpArrow:
                    // Up
                    [self selectPreviousRow];
                    break;
                case kVK_Tab:
                    if ([theEvent modifierFlags] & NSShiftKeyMask) {
                        [self selectPreviousRow];
                    } else {
                        [self selectNextRow];
                    }
                    break;
                case kVK_Return:
                    [self activateSelectedWindow];
                    [self resetWindowInfoAndViewSize];
                    [self deactivatePanel];
                    break;
                case kVK_Escape:
                    if ([self.windowInfoArray count] != 0) {
                        [self activateWindowByIndex:0];
                    }
                    [self deactivatePanel];
                    break;
                default:
                    break;
            }
        }
    }
}

- (void)mouseDownAtTable:(NSEvent *)theEvent
{
    NSPoint globalLocation = [theEvent locationInWindow];
    NSPoint localLocation = [self.table convertPoint:globalLocation fromView:nil];
    NSInteger clickedRow = [self.table rowAtPoint:localLocation];
    
    [self activateWindowByIndex:clickedRow];
    [self resetWindowInfoAndViewSize];
}

#pragma mark - initializer

- (void)initializeVariables
{
    self.isKeyRegisteringMode = NO;
    self.windowInfoArray = [[NSMutableArray alloc] init];
    self.allShowingWinKey = [[NSMutableArray alloc] init];
    
    defaultPanelX = self.panel.frame.origin.x;
    defaultPanelY = self.panel.frame.origin.y;
    defaultPanelWidth = self.panel.frame.size.width;
    defaultPanelHeight = self.panel.frame.size.height;
    
    defaultPaddingX = self.padding.frame.origin.x;
    defaultPaddingY = self.padding.frame.origin.y;
    defaultPaddingWidth = self.padding.frame.size.width;
    defaultPaddingHeight = self.padding.frame.size.height;

    defaultScrollViewX = self.scrollView.frame.origin.x;
    defaultScrollViewY = self.scrollView.frame.origin.y;
    defaultScrollViewWidth = self.scrollView.frame.size.width;
    defaultScrollViewHeight = self.scrollView.frame.size.height;
    
    defaultTableHeight = self.table.frame.size.height;
}

- (void)initializeFirstExecution
{
    // For test
//    [self setHasFirstExecution:NO];
    
    if (![self hasFirstExecution]) {
        [self setHasFirstExecution:YES];
        
        [self initializePreferences];
        [self showTutorial];
    }
}

- (void)initializePreferences
{
//    [self setIsStartupEnabled:NO];
    [self setIsHotKeyEnabled:YES];
//    [self setIsReplaceCmdTabEnabled:NO];
}

- (void)showTutorial
{
    // TODO: show a tutorial
}

- (BOOL)hasFirstExecution
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kPreferenceInitialization];
}

- (void)setHasFirstExecution:(BOOL)hasFirstExecution
{
    [[NSUserDefaults standardUserDefaults] setBool:hasFirstExecution forKey:kPreferenceInitialization];
}

- (BOOL)isAccessibilityEnabled
{
    NSDictionary *options = @{(__bridge id)kAXTrustedCheckOptionPrompt: @YES};
    BOOL accessibilityEnabled = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
    return accessibilityEnabled;
}

- (void)checkAccessibility
{
    // If the accessibility is disabled, the system preference will open.
    [self isAccessibilityEnabled];
}

- (void)openAccessibility
{
    NSString *script = [NSString stringWithFormat:@"tell application \"System Preferences\" \n set securityPane to pane id \"com.apple.preference.security\" \n tell securityPane to reveal anchor \"Privacy_Accessibility\" \n activate \n end tell"];
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:script];
    [appleScript executeAndReturnError:nil];
}

#pragma mark - window info

- (void)registerWinKey:(NSString *)keyString
{
    NSInteger selectedRow = [self.table selectedRow];
    [self saveWinKey:keyString];
    [self endKeyRegisteringMode:selectedRow];
}

- (void)resetWindowInfo
{
    @synchronized (self) {
        self.isKeyRegisteringMode = NO;
    
        self.windowInfoArray = [[NSMutableArray alloc] init];
        
        NSArray *apps = [[NSWorkspace sharedWorkspace] runningApplications];
        CFArrayRef windowList = CGWindowListCopyWindowInfo((kCGWindowListOptionOnScreenOnly|kCGWindowListExcludeDesktopElements), kCGNullWindowID);
        //    CFArrayRef windowList = CGWindowListCopyWindowInfo((kCGWindowListOptionAll|kCGWindowListOptionOnScreenOnly|kCGWindowListExcludeDesktopElements), kCGNullWindowID);
        //    CFArrayRef windowList = CGWindowListCopyWindowInfo((kCGWindowListOptionOnScreenOnly), kCGNullWindowID);
        //    CFArrayRef windowList = CGWindowListCopyWindowInfo((kCGWindowListOptionOnScreenAboveWindow), kCGNullWindowID);
        //    CFArrayRef windowList = CGWindowListCopyWindowInfo((kCGWindowListExcludeDesktopElements), kCGNullWindowID);
        
        for (int i = 0; i < CFArrayGetCount(windowList); i++) {
            BOOL flg = NO;
            CFDictionaryRef dict = CFArrayGetValueAtIndex(windowList, i);
            
            if ((int)CFDictionaryGetValue(dict, kCGWindowLayer) > 1000) {
                continue;
            }
            
            //        CFStringRef ownerRef = CFDictionaryGetValue(dict, kCGWindowOwnerName);
            //        NSString *owner = (__bridge_transfer NSString *)ownerRef;
            NSImage *icon = [[NSImage alloc] initWithSize:NSMakeSize(32, 32)];
            NSString *appName = nil;
            
            CFNumberRef ownerPidRef = CFDictionaryGetValue(dict, kCGWindowOwnerPID);
            NSInteger ownerPid = [(__bridge_transfer NSNumber *)ownerPidRef integerValue];
            
            for (NSRunningApplication* app in apps) {
                if (ownerPid == app.processIdentifier) {
                    appName = app.localizedName;
                    [icon lockFocus];
                    [app.icon drawInRect:NSMakeRect(0, 0, icon.size.width, icon.size.height)
                                fromRect:NSMakeRect(0, 0, app.icon.size.width, app.icon.size.height)
                               operation:NSCompositeCopy
                                fraction:1.0f];
                    [icon unlockFocus];
                    flg = YES;
                    break;
                }
            }
            if (!flg) continue;
            
            // exclude this app
            if ([appName isEqualToString:@"HotSwitch"]) continue;
            
            CFStringRef n = CFDictionaryGetValue(dict, kCGWindowName);
            NSString *winName = (__bridge_transfer NSString *) n;
            if (winName == nil) continue;
            if ([winName isEqualToString:@""]) {
                winName = appName;
            }
            
            NSNumber *alpha = CFDictionaryGetValue(dict, kCGWindowAlpha);
            NSNumber *layer = CFDictionaryGetValue(dict, kCGWindowLayer);
            if (!([layer integerValue] == 0 && [alpha integerValue] > 0)) continue;
            
            NSNumber *winId = CFDictionaryGetValue(dict, kCGWindowNumber);
            
            CFDictionaryRef winBoundsRef = CFDictionaryGetValue(dict, kCGWindowBounds);
            NSDictionary *winBounds = (__bridge NSDictionary*)winBoundsRef;
            NSInteger x = [[winBounds objectForKey:@"X"] integerValue];
            NSInteger y = [[winBounds objectForKey:@"Y"] integerValue];
            NSInteger width = [[winBounds objectForKey:@"Width"] integerValue];
            NSInteger height = [[winBounds objectForKey:@"Height"] integerValue];
            
            WindowInfoModel *model = [[WindowInfoModel alloc] init];
            model.key = @"";
            model.icon = icon;
            model.winName = winName;
            model.appName = appName;
            model.winId = winId;
            model.pid = ownerPid;
            model.x = x;
            model.y = y;
            model.width = width;
            model.height = height;
            
            [self.windowInfoArray addObject:model];
        }
        
        [self removeDuplicateWindowInfo];
        
        [self setWinKeyToWindowInfo];
        
        [self.arrayController setContent:self.windowInfoArray];
    }
}

- (void)resetWindowInfoAndViewSize
{
    [self resetWindowInfo];
    [self resetViewSize];
}

- (void)removeDuplicateWindowInfo
{
    // TODO: There is a broblem.
    // When you use "XtraFinder", two windows of the Finder is showed for some reason.
    // So, this code check the duplicate window and ignore a window.
    
    NSInteger firstX = 0;
    NSInteger firstY = 0;
    NSInteger firstWidth = 0;
    NSInteger firstHeight = 0;
    NSString *firstWinName = @"";
    
    NSMutableArray *duplicateWindowInfoArray = [[NSMutableArray alloc] init];
    
    for (WindowInfoModel *model in self.windowInfoArray) {
        if (![model.appName isEqualToString:@"Finder"]) {
            continue;
        }
        
        if (([model.winName isEqualToString:firstWinName]) && (model.x == firstX && model.width == firstWidth) && ((model.y - firstY) + (model.height - firstHeight) == 0)) {
            // the window name is same
            // and, the weight is same
            // and, the y difference and the height is same
            // -> this judge that the duplicate window of "XtraFinder" is created
            [duplicateWindowInfoArray addObject:model];
            
            firstX = 0;
            firstY = 0;
            firstWidth = 0;
            firstHeight = 0;
        } else {
            firstX = model.x;
            firstY = model.y;
            firstWidth = model.width;
            firstHeight = model.height;
            firstWinName = model.winName;
        }
    }
    
    for (WindowInfoModel *model in duplicateWindowInfoArray) {
        [self.windowInfoArray removeObject:model];
    }
}

- (void)setWinKeyToWindowInfo
{
    for (WindowInfoModel *model in self.windowInfoArray) {
        NSString *winKey = [self winKeyByWindowInfo:model];
        model.key = winKey;
        
        [self.allShowingWinKey addObject:winKey];
    }
}

- (NSString*)winKeyByWindowInfo:(WindowInfoModel*)model
{
    NSMutableArray *allWinKey = [self loadAllWinKey];
    
    NSString *appName = model.appName;
    NSInteger winIdIndex = [self appWinIdIndex:model];
    
    for (NSDictionary *winKeyDic in allWinKey) {
        if ([[winKeyDic objectForKey:@"appName"] isEqualToString:appName]) {
            NSMutableArray *winKeyArray = [winKeyDic objectForKey:@"key"];
            if ([winKeyArray count] - 1 >= winIdIndex) {
                NSString *winKey = [winKeyArray objectAtIndex:winIdIndex];
                return winKey;
            } else {
                return @"";
            }
        }
    }
    
    return @"";
}

- (void)activateSelectedWindowByKey:(NSString*)theWinKey
{
    NSMutableArray *allWinKey = [self loadAllWinKey];
    
    for (NSDictionary *winKeyDic in allWinKey) {
        NSMutableArray *winKeyArray = [winKeyDic objectForKey:@"key"];
        for (int i = 0; i < [winKeyArray count]; i++) {
            if ([[winKeyArray objectAtIndex:i] isEqualToString:theWinKey]) {
                
                NSString *appName = [winKeyDic objectForKey:@"appName"];
                
                WindowInfoModel *model = [self windowInfoModelFromWinIdIndex:i appName:appName];
                [self activateWindow:model];
                return;
            }
        }
    }
}

- (void)activateSelectedWindow
{
    NSArray* selections = [self.arrayController selectedObjects];
    if (!selections || [selections count] <= 0) return;

    WindowInfoModel *model = [selections objectAtIndex:0];
    [self activateWindow:model];
}

- (void)activateWindowByIndex:(NSInteger)index
{
    WindowInfoModel *model = [self.windowInfoArray objectAtIndex:index];
    [self activateWindow:model];
}

- (void)activateWindow:(WindowInfoModel*)model
{
    CGWindowID win_id = (int)[model.winId integerValue];
    
    // some AXUIElementCreateByWindowNumber would be soooo nice. but nope, we have to take the pain below.
    int pid = (int)model.pid;
    
    AXUIElementRef app = AXUIElementCreateApplication(pid);
    CFArrayRef appwindows;
    AXUIElementCopyAttributeValues(app, kAXWindowsAttribute, 0, 1000, &appwindows);
    if (appwindows) {
        // looks like appwindows can be NULL when this function is called during the
        // switch-workspaces animation
        for (id w in (__bridge NSArray*)appwindows) {
            AXUIElementRef win = (__bridge AXUIElementRef)w;
            CGWindowID tmp;
            _AXUIElementGetWindow(win, &tmp); //XXX: undocumented API. but the alternative is horrifying.
            if (tmp == win_id) {
                // finally got it, activate the window
                AXUIElementPerformAction(win, kAXRaiseAction);
                
                // TODO: The later method is deprecated. So, switching to the former method may be good.
                // [[NSApplication sharedApplication] activateIgnoringOtherApps: YES].
                ProcessSerialNumber process;
                GetProcessForPID(pid, &process);
                SetFrontProcessWithOptions(&process, kSetFrontProcessFrontWindowOnly);
                break;
            }
        }
        CFRelease(appwindows);
    }
    CFRelease(app);
}

- (NSInteger)winOrderIndexByWindowInfoModel:(WindowInfoModel*)theModel
{
    NSString *theAppName = theModel.appName;
    
    NSMutableArray *windowInfoArrayOnlyTheApp = [[NSMutableArray alloc] init];
    for (WindowInfoModel *model in self.windowInfoArray) {
        if ([model.appName isEqualToString:theAppName]) {
            [windowInfoArrayOnlyTheApp addObject:model];
        }
    }
    
    NSInteger winOrderIndex = [windowInfoArrayOnlyTheApp indexOfObject:theModel] + 1;
    return winOrderIndex;
}

#pragma mark - panel

- (void)deactivatePanel
{
    [self.panel orderOut:self];
}

- (void)activatePanel
{
//    [self.panel makeKeyWindow];
    [self.panel makeKeyAndOrderFront:self];
//    [self.panel orderFront:self];
    
    [[NSApplication sharedApplication] activateIgnoringOtherApps : YES];
    
    [self.panel makeFirstResponder:self.table];
}

#pragma mark - settings

- (BOOL)isHotKeyEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kPreferenceGlobalShortcutEnabled];
}

- (void)setIsHotKeyEnabled:(BOOL)enabled
{
    if (self.isHotKeyEnabled != enabled) {
        [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:kPreferenceGlobalShortcutEnabled];
        [self resetHotkeyRegistration];
    }
}

- (BOOL)isReplaceCmdTabEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kPreferenceReplaceCmdTabEnabled];
}

- (void)setIsReplaceCmdTabEnabled:(BOOL)isReplaceCmdTabEnabled
{
    if (self.isReplaceCmdTabEnabled != isReplaceCmdTabEnabled) {
        [[NSUserDefaults standardUserDefaults] setBool:isReplaceCmdTabEnabled forKey:kPreferenceReplaceCmdTabEnabled];
        [self resetReplacingCmdTab];
    }
}

- (BOOL)isStartupEnabled
{
	BOOL is_enable = NO;
	CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath: [[NSBundle mainBundle] bundlePath]];
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	
	UInt32 seedValue;
	NSArray  *loginItemsArray = (__bridge NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
	for (id item in loginItemsArray) {
		LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)item;
		if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &url, NULL) == noErr) {
			if ([[(__bridge NSURL *)url path] hasPrefix:[[NSBundle mainBundle] bundlePath]]) {
				is_enable = YES;
				break;
			}
		}
	}
	CFRelease(loginItems);
	
	return is_enable;
}

- (void)setIsStartupEnabled:(BOOL)isStartupEnabled
{
    if (isStartupEnabled) {
        CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath: [[NSBundle mainBundle] bundlePath]];
        
        LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
        LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemLast, NULL, NULL, url, NULL, NULL);		
        if (item) {
            CFRelease(item);
        }
        CFRelease(loginItems);
        
    } else {
        CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath: [[NSBundle mainBundle] bundlePath]];
        LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
        UInt32 seedValue;
        NSArray  *loginItemsArray = (__bridge NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
        for (id item in loginItemsArray)
        {		
            LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)item;
            if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &url, NULL) == noErr)
            {
                if ([[(__bridge NSURL *)url path] hasPrefix:[[NSBundle mainBundle] bundlePath]]) {
                    LSSharedFileListItemRemove(loginItems, itemRef);
                    break;
                }
            }
        }
        CFRelease(loginItems);
    }
}

- (void)initializeHotkey
{
    [self registerDefaultHotkey];
    
    // Shortcut view will follow and modify user preferences automatically
    self.shortcutView.associatedUserDefaultsKey = kPreferenceGlobalShortcut;
    
    [self resetHotkeyRegistration];
    
    [self initializeRegistrationCmdTab];
    [self resetReplacingCmdTab];
    
    // For test
//    [self resetConstantHotkeyRegistration];
}

- (void)registerDefaultHotkey
{
    // Default shortcut
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:kPreferenceGlobalShortcut];
    if (data == nil) {
        MASShortcut *defaultShortcut = [MASShortcut shortcutWithKeyCode:kVK_ANSI_Period modifierFlags:NSCommandKeyMask];
        [MASShortcut setGlobalShortcut:defaultShortcut forUserDefaultsKey:kPreferenceGlobalShortcut];
    }
}

- (void)resetHotkeyRegistration
{
    if (self.isHotKeyEnabled) {
        // Execute your block of code automatically when user triggers a shortcut from preferences
        [MASShortcut registerGlobalShortcutWithUserDefaultsKey:kPreferenceGlobalShortcut handler:^{
            [self executeHotkey];
        }];
    } else {
        [MASShortcut unregisterGlobalShortcutWithUserDefaultsKey:kPreferenceGlobalShortcut];
    }
    
}

- (void)resetConstantHotkeyRegistration
{
    // Assing Cmd-F2
    MASShortcut *shortcut = [MASShortcut shortcutWithKeyCode:kVK_F2 modifierFlags:NSCommandKeyMask];
    [MASShortcut addGlobalHotkeyMonitorWithShortcut:shortcut handler:^{
        [self executeHotkey];
    }];
}

- (void)executeHotkey
{
    if (![self.panel isKeyWindow]) {
        [self resetWindowInfoAndViewSize];
        
        [self selectNextRow];
        
        [self activatePanel];
    } else {
        [self deactivatePanel];
    }
}

- (void)resetReplacingCmdTab
{
    if (self.isReplaceCmdTabEnabled) {
        [self registerCmdTab];
    } else {
        [self unregisterCmdTab];
    }
}

// This callback will be invoked every time there is a keystroke.
CGEventRef myCGEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon)
{
    // Paranoid sanity check.
    if ((type != kCGEventKeyDown) && (type != kCGEventKeyUp)) return event;
    
    // The incoming keycode.
    CGKeyCode keycode = (CGKeyCode)CGEventGetIntegerValueField( event, kCGKeyboardEventKeycode);
    CGEventFlags eventFlags = CGEventGetFlags(event);
    
    // Replace Cmd-Tab
    if (keycode == (CGKeyCode)48) {
        // Tab
//        BOOL isModifierPressed = ((eventFlags & (kCGEventFlagMaskAlternate | kCGEventFlagMaskCommand | kCGEventFlagMaskControl | kCGEventFlagMaskShift)) > 0);
        BOOL isCmdModifierPressed = ((eventFlags & (kCGEventFlagMaskCommand)) > 0);
        if (isCmdModifierPressed) {
            if (type == kCGEventKeyDown) {
                // ここでは self が参照できなかったため、NSApplicationから取得
                [(AppDelegate*) [[NSApplication sharedApplication] delegate] executeHotkey];
                return nil;
            }
        }
    }
    
    // Set the modified keycode field in the event.
    CGEventSetIntegerValueField(event, kCGKeyboardEventKeycode, (int64_t)keycode);
    
    // We must return the event for it to be useful.
    return event;
}

- (void)initializeRegistrationCmdTab
{
    // Create an event tap. We are interested in key presses.
    eventMask = ((1 << kCGEventKeyDown) | (1 << kCGEventKeyUp));
    eventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, 0, eventMask, myCGEventCallback, NULL);
    if (!eventTap) {
        fprintf(stderr, "failed to create event tap\n");
        exit(1);
    }
    
    // Create a run loop source.
    runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
    
    // Add to the current run loop.
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
    
    // Enable the event tap.
    CGEventTapEnable(eventTap, true);
    
    // Set it all running.
    CFRunLoopRun();
}

- (void)registerCmdTab
{
    // Add to the current run loop.
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
    
    // Enable the event tap.
    CGEventTapEnable(eventTap, true);
}

- (void)unregisterCmdTab
{
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
    
    CGEventTapEnable(eventTap, false);
}

#pragma mark - registraton mode

- (void)startKeyRegisteringMode
{
    self.isKeyRegisteringMode = YES;
    
    [self.table setRegistrationMode:YES];
    [self redrawRow];
}

- (void)endKeyRegisteringMode
{
    NSInteger selectedRow = [self.table selectedRow];
    [self endKeyRegisteringMode:selectedRow];
    
    [self.table setRegistrationMode:NO];
    [self redrawRow];
}

- (void)endKeyRegisteringMode:(NSInteger)selectedRow
{
    self.isKeyRegisteringMode = NO;
    [self resetWindowInfo];
    [self.table selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
}

#pragma mark - win key

- (NSString*)selectedAppName
{
    WindowInfoModel *selectedModel = [self.windowInfoArray objectAtIndex:[self.table selectedRow]];
    return selectedModel.appName;
}

- (NSInteger)selectedAppWinIdIndex
{
    WindowInfoModel *selectedModel = [self.windowInfoArray objectAtIndex:[self.table selectedRow]];
    return [self appWinIdIndex:selectedModel];
}

- (NSInteger)appWinIdIndex:(WindowInfoModel*)selectedModel
{
    NSMutableArray *windowInfoArrayOnlySelectedApp = [[NSMutableArray alloc] init];
    for (WindowInfoModel *model in self.windowInfoArray) {
        if ([selectedModel.appName isEqualToString:model.appName]) {
            [windowInfoArrayOnlySelectedApp addObject:model];
        }
    }
    
    NSInteger selectedAppWinIdIndex = 0;
    
    windowInfoArrayOnlySelectedApp = [[windowInfoArrayOnlySelectedApp sortedArrayUsingSelector:@selector(compareWinId:)] mutableCopy];
    for (int i = 0; i < windowInfoArrayOnlySelectedApp.count; i++) {
        WindowInfoModel *model = [windowInfoArrayOnlySelectedApp objectAtIndex:i];
        if ([model.winId isEqualToNumber:selectedModel.winId]) {
            selectedAppWinIdIndex = i;
        }
    }
    
    return selectedAppWinIdIndex;
}

- (WindowInfoModel*)windowInfoModelFromWinIdIndex:(NSInteger)selectedAppWinIdIndex appName:(NSString*)selectedAppName
{
    NSMutableArray *windowInfoArrayOnlySelectedApp = [[NSMutableArray alloc] init];
    for (WindowInfoModel *model in self.windowInfoArray) {
        if ([model.appName isEqualToString:selectedAppName]) {
            [windowInfoArrayOnlySelectedApp addObject:model];
        }
    }
    
    windowInfoArrayOnlySelectedApp = [[windowInfoArrayOnlySelectedApp sortedArrayUsingSelector:@selector(compareWinId:)] mutableCopy];
    WindowInfoModel *selectedModel = [windowInfoArrayOnlySelectedApp objectAtIndex:selectedAppWinIdIndex];
    return selectedModel;
}

- (BOOL)hasTheAppWinKey:(NSMutableArray*)allWinKey
{
    for (NSDictionary *winKeyDic in allWinKey) {
        NSString *appName = [winKeyDic objectForKey:@"appName"];
        if ([[self selectedAppName] isEqualToString:appName]) {
            return YES;
        }
    }
    return NO;
}

- (void)removeDupulicateWinKey:(NSString*)selectedWinKey allWinKey:(NSMutableArray*)allWinKey
{
    // If the selected key is duplicate, the former key is removed.
    for (NSDictionary *winKeyDic in allWinKey) {
        NSMutableArray *winKeyArray = [winKeyDic objectForKey:@"key"];
        for (NSString *winKey in winKeyArray) {
            if ([winKey isEqualToString:selectedWinKey]) {
                [winKeyArray removeObject:winKey];
                if ([winKeyArray count] == 0) {
                    [allWinKey removeObject:winKeyDic];
                }
                return;
            }
        }
    }
    return;
}

- (void)saveWinKey:(NSString*)selectedWinKey
{
    NSMutableArray *allWinKey = [self loadAllWinKey];
    
    [self removeDupulicateWinKey:selectedWinKey allWinKey:allWinKey];
    
    // add the new key
    if ([self hasTheAppWinKey:allWinKey]) {
        for (NSDictionary *winKeyDic in allWinKey) {
            NSString *appName = [winKeyDic objectForKey:@"appName"];
            if ([[self selectedAppName] isEqualToString:appName]) {
                NSMutableArray *winKeyArray = [winKeyDic objectForKey:@"key"];
                if ([winKeyArray count] - 1 < [self selectedAppWinIdIndex]) {
                    [winKeyArray addObject:selectedWinKey];
                } else {
                    [winKeyArray replaceObjectAtIndex:[self selectedAppWinIdIndex] withObject:selectedWinKey];
                }
            }
        }
    } else {
        NSMutableArray *winKeyArray = [[NSMutableArray alloc] init];
        [winKeyArray addObject:selectedWinKey];
        NSDictionary *winKeyDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [self selectedAppName],@"appName",
                                   winKeyArray,@"key",
                                   nil];
        
        [allWinKey addObject:winKeyDic];
    }
    
    // save the preferences
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:allWinKey];
    [ud setObject:data forKey:kPreferenceWinKey];
}

- (void)deleteSelectedWinKey
{
    NSInteger selectedRow = [self.table selectedRow];
    
    // remove the duplicate key
    NSMutableArray *allWinKey = [self loadAllWinKey];
    WindowInfoModel *model = [self.windowInfoArray objectAtIndex:selectedRow];
    NSString *winKey = [self winKeyByWindowInfo:model];
    [self removeDupulicateWinKey:winKey allWinKey:allWinKey];
    
    // save the preferences
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:allWinKey];
    [ud setObject:data forKey:kPreferenceWinKey];
    
    // reset the window info
    [self resetWindowInfo];
    [self.table selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
}

- (NSMutableArray*)loadAllWinKey
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSData *data = [ud objectForKey:kPreferenceWinKey];
    NSMutableArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if (array == nil) {
        array = [[NSMutableArray alloc] init];
    }
    
    return array;
}

- (void)clearWinKey
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[[NSMutableArray alloc] init]];
    [ud setObject:data forKey:kPreferenceWinKey];
}

- (void)setupStatusMenu
{
    NSStatusBar *systemStatusBar = [NSStatusBar systemStatusBar];
    self.statusItem = [systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setHighlightMode:YES];
    [self.statusItem setTitle:@""];
    [self.statusItem setImage:[NSImage imageNamed:kMenuAppIconName]];
    [self.statusItem setMenu:self.statusMenu];
}

#pragma mark - view

- (void)resetViewSize
{
    // reset the size to default value
    // It is need to minimize the view from large view to small view.
    // This default value is smallest for window size.
    [self.arrayController setContent:[[NSMutableArray alloc] init]];
    [self.panel setFrame:CGRectMake(defaultPanelX, defaultPanelY, defaultPanelWidth, defaultPanelHeight) display:YES animate:NO];
    self.padding.frame = CGRectMake(defaultPaddingX, defaultPaddingY, defaultPaddingWidth, defaultPaddingHeight);
    self.scrollView.frame = CGRectMake(defaultScrollViewX, defaultScrollViewY, defaultScrollViewWidth, defaultScrollViewHeight);
    self.table.frame = CGRectMake(self.table.frame.origin.x, self.table.frame.origin.x, self.table.frame.size.width, defaultTableHeight);
    
    // set window info
    [self.arrayController setContent:self.windowInfoArray];
    
    // reset position and size for caluculated value
    CGFloat tableHeight = self.table.frame.size.height;
    CGFloat diff_height = (-defaultScrollViewHeight) + tableHeight;
    CGFloat panelHeight = defaultPanelHeight + diff_height;
    
    NSRect screen = [[NSScreen mainScreen] visibleFrame];
    
    [self.panel setFrame:CGRectMake((screen.size.width - defaultPanelWidth) / 2, (screen.size.height - panelHeight) / 2, defaultPanelWidth, panelHeight) display:YES animate:NO];
    self.padding.frame = CGRectMake(defaultPaddingX, defaultPaddingY, defaultPaddingWidth, defaultPaddingHeight + diff_height);
    self.scrollView.frame = CGRectMake(defaultScrollViewX, defaultScrollViewY, defaultScrollViewWidth, defaultScrollViewHeight + diff_height);
}

- (void)selectNextRow
{
    NSInteger selectedRow = [self.table selectedRow];
    NSInteger lastRow = [self.windowInfoArray count] - 1;
    if (selectedRow >= lastRow) {
        [self.table selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    } else {
        [self.table selectRowIndexes:[NSIndexSet indexSetWithIndex:(selectedRow + 1)] byExtendingSelection:NO];
    }
}

- (void)selectPreviousRow
{
    NSInteger selectedRow = [self.table selectedRow];
    NSInteger lastRow = [self.windowInfoArray count] - 1;
    if (selectedRow <= 0) {
        [self.table selectRowIndexes:[NSIndexSet indexSetWithIndex:lastRow] byExtendingSelection:NO];
    } else {
        [self.table selectRowIndexes:[NSIndexSet indexSetWithIndex:(selectedRow - 1)] byExtendingSelection:NO];
    }
}

- (void)redrawRow
{
    [self selectNextRow];
    [self selectPreviousRow];
}

#pragma mark - key checker

- (BOOL)isShowingWinKey:(NSString*)theWinKey
{
    for (NSString *winKey in self.allShowingWinKey) {
        if ([theWinKey isEqualToString:winKey]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isRegisterableKey:(NSInteger)keyCode unicodeKey:(unichar)unicodeKey
{
    switch (unicodeKey) {
        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
        case 'a':
        case 'b':
        case 'c':
        case 'd':
        case 'e':
        case 'f':
        case 'g':
        case 'h':
        case 'i':
        case 'j':
        case 'k':
        case 'l':
        case 'm':
        case 'n':
        case 'o':
        case 'p':
        case 'q':
        case 'r':
        case 's':
        case 't':
        case 'u':
        case 'v':
        case 'w':
        case 'x':
        case 'y':
        case 'z':
        case 'A':
        case 'B':
        case 'C':
        case 'D':
        case 'E':
        case 'F':
        case 'G':
        case 'H':
        case 'I':
        case 'J':
        case 'K':
        case 'L':
        case 'M':
        case 'N':
        case 'O':
        case 'P':
        case 'Q':
        case 'R':
        case 'S':
        case 'T':
        case 'U':
        case 'V':
        case 'W':
        case 'X':
        case 'Y':
        case 'Z':
        case '-':
        case '^':
        case '\\':
        case '@':
        case '[':
        case ']':
        case ';':
        case ':':
        case ',':
        case '.':
        case '/':
        case '_':
        case '=':
        case '~':
        case '|':
        case '`':
        case '{':
        case '}':
        case '+':
        case '*':
        case '<':
        case '>':
        case '?':
        case '!':
        case '"':
        case '#':
        case '$':
        case '%':
        case '&':
        case '\'':
        case '(':
        case ')':
            return YES;
    }
    
    switch (keyCode) {
        case kVK_ANSI_A:
        case kVK_ANSI_S:
        case kVK_ANSI_D:
        case kVK_ANSI_F:
        case kVK_ANSI_H:
        case kVK_ANSI_G:
        case kVK_ANSI_Z:
        case kVK_ANSI_X:
        case kVK_ANSI_C:
        case kVK_ANSI_V:
        case kVK_ANSI_B:
        case kVK_ANSI_Q:
        case kVK_ANSI_W:
        case kVK_ANSI_E:
        case kVK_ANSI_R:
        case kVK_ANSI_Y:
        case kVK_ANSI_T:
        case kVK_ANSI_1:
        case kVK_ANSI_2:
        case kVK_ANSI_3:
        case kVK_ANSI_4:
        case kVK_ANSI_6:
        case kVK_ANSI_5:
        case kVK_ANSI_Equal:
        case kVK_ANSI_9:
        case kVK_ANSI_7:
        case kVK_ANSI_Minus:
        case kVK_ANSI_8:
        case kVK_ANSI_0:
        case kVK_ANSI_RightBracket:
        case kVK_ANSI_O:
        case kVK_ANSI_U:
        case kVK_ANSI_LeftBracket:
        case kVK_ANSI_I:
        case kVK_ANSI_P:
        case kVK_ANSI_L:
        case kVK_ANSI_J:
        case kVK_ANSI_Quote:
        case kVK_ANSI_K:
        case kVK_ANSI_Semicolon:
        case kVK_ANSI_Backslash:
        case kVK_ANSI_Comma:
        case kVK_ANSI_Slash:
        case kVK_ANSI_N:
        case kVK_ANSI_M:
        case kVK_ANSI_Period:
            return YES;
        default:
            return NO;
    }
}

- (NSString*)keyStringByKeyCode:(NSInteger)keyCode unicodeKey:(unichar)unicodeKey
{
    switch (unicodeKey) {
        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
        case 'a':
        case 'b':
        case 'c':
        case 'd':
        case 'e':
        case 'f':
        case 'g':
        case 'h':
        case 'i':
        case 'j':
        case 'k':
        case 'l':
        case 'm':
        case 'n':
        case 'o':
        case 'p':
        case 'q':
        case 'r':
        case 's':
        case 't':
        case 'u':
        case 'v':
        case 'w':
        case 'x':
        case 'y':
        case 'z':
        case 'A':
        case 'B':
        case 'C':
        case 'D':
        case 'E':
        case 'F':
        case 'G':
        case 'H':
        case 'I':
        case 'J':
        case 'K':
        case 'L':
        case 'M':
        case 'N':
        case 'O':
        case 'P':
        case 'Q':
        case 'R':
        case 'S':
        case 'T':
        case 'U':
        case 'V':
        case 'W':
        case 'X':
        case 'Y':
        case 'Z':
        case '-':
        case '^':
        case '\\':
        case '@':
        case '[':
        case ']':
        case ';':
        case ':':
        case ',':
        case '.':
        case '/':
        case '_':
        case '=':
        case '~':
        case '|':
        case '`':
        case '{':
        case '}':
        case '+':
        case '*':
        case '<':
        case '>':
        case '?':
        case '!':
        case '"':
        case '#':
        case '$':
        case '%':
        case '&':
        case '\'':
        case '(':
        case ')':
            return [NSString stringWithCharacters:&unicodeKey length:1];
    }
    
    switch (keyCode) {
        case kVK_ANSI_A:
            return @"a";
        case kVK_ANSI_S:
            return @"s";
        case kVK_ANSI_D:
            return @"d";
        case kVK_ANSI_F:
            return @"f";
        case kVK_ANSI_H:
            return @"h";
        case kVK_ANSI_G:
            return @"g";
        case kVK_ANSI_Z:
            return @"z";
        case kVK_ANSI_X:
            return @"x";
        case kVK_ANSI_C:
            return @"c";
        case kVK_ANSI_V:
            return @"v";
        case kVK_ANSI_B:
            return @"b";
        case kVK_ANSI_Q:
            return @"q";
        case kVK_ANSI_W:
            return @"w";
        case kVK_ANSI_E:
            return @"e";
        case kVK_ANSI_R:
            return @"r";
        case kVK_ANSI_Y:
            return @"y";
        case kVK_ANSI_T:
            return @"t";
        case kVK_ANSI_1:
            return @"1";
        case kVK_ANSI_2:
            return @"2";
        case kVK_ANSI_3:
            return @"3";
        case kVK_ANSI_4:
            return @"4";
        case kVK_ANSI_6:
            return @"6";
        case kVK_ANSI_5:
            return @"5";
        case kVK_ANSI_Equal:
            return @"=";
        case kVK_ANSI_9:
            return @"9";
        case kVK_ANSI_7:
            return @"7";
        case kVK_ANSI_Minus:
            return @"-";
        case kVK_ANSI_8:
            return @"8";
        case kVK_ANSI_0:
            return @"0";
        case kVK_ANSI_RightBracket:
            return @"[";
        case kVK_ANSI_O:
            return @"0";
        case kVK_ANSI_U:
            return @"u";
        case kVK_ANSI_LeftBracket:
            return @"]";
        case kVK_ANSI_I:
            return @"i";
        case kVK_ANSI_P:
            return @"p";
        case kVK_ANSI_L:
            return @"l";
        case kVK_ANSI_J:
            return @"j";
        case kVK_ANSI_Quote:
            return @"'";
        case kVK_ANSI_K:
            return @"k";
        case kVK_ANSI_Semicolon:
            return @";";
        case kVK_ANSI_Backslash:
            return @"\\";
        case kVK_ANSI_Comma:
            return @",";
        case kVK_ANSI_Slash:
            return @"/";
        case kVK_ANSI_N:
            return @"n";
        case kVK_ANSI_M:
            return @"m";
        case kVK_ANSI_Period:
            return @".";
        default:
            return @"";
    }
}

@end
