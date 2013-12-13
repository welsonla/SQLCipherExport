//
//  Utility.h
//  SQLCipherManager
//
//  Created by wanyc on 13-11-21.
//  Copyright (c) 2013年 Wan Yechao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utility : NSObject

+ (NSString *)formatTime:(NSDate *)date;

+ (void)openInFinder:(NSString *)filePath;

@end
