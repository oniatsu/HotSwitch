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
@property (nonatomic) NSString *winName;
@property (nonatomic) NSString *appName;
@property (nonatomic) NSNumber *winId;
@property (nonatomic) NSColor* textColor;
@property (nonatomic) NSInteger pid;
@property (nonatomic) NSInteger x;
@property (nonatomic) NSInteger y;
@property (nonatomic) NSInteger width;
@property (nonatomic) NSInteger height;

@end
