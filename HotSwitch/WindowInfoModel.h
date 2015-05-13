//
//  WindowInfoModel.h
//  HotSwitch
//
//  Created by oniatsu on 2014/09/13.
//  Copyright (c) 2014年 oniatsu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WindowInfoModel : NSObject

@property (nonatomic) NSString *key;

@property (nonatomic) NSImage *icon;

@property (nonatomic) NSString *originalWinName;
@property (nonatomic) NSString *winName;
@property (nonatomic) NSString *appName;
@property (nonatomic) NSInteger winId;
@property (nonatomic) NSInteger pid;

@property (nonatomic) AXUIElementRef uiEle;
@property (nonatomic) NSDictionary* uiEleAttributes;
//@property (nonatomic) NSArray* uiEleChildren;

@property (nonatomic) NSInteger x;
@property (nonatomic) NSInteger y;
@property (nonatomic) NSInteger width;
@property (nonatomic) NSInteger height;

@end
