//
//  Utility.m
//  SQLCipherManager
//
//  Created by wanyc on 13-11-21.
//  Copyright (c) 2013年 Wan Yechao. All rights reserved.
//

#import "Utility.h"

@implementation Utility

+ (NSString *)formatTime:(NSDate *)date{
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];
    [formater setDateFormat:@"yyMMdd_HHmmss"];
    return [formater stringFromDate:date];
}

@end
