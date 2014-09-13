//
//  WindowInfoModel.m
//  HotSwitch
//
//  Created by oniatsu on 2014/09/13.
//  Copyright (c) 2014年 oniatsu. All rights reserved.
//

#import "WindowInfoModel.h"

@implementation WindowInfoModel

- (NSComparisonResult) compareWinId:(WindowInfoModel*) model {
    if (self.winId > model.winId) {
        return NSOrderedDescending;
    } else if(self.winId < model.winId) {
        return NSOrderedAscending;
    } else {
        return NSOrderedSame;
    }
}

@end
