//
//  AppDelegate.h
//  SQLCipherManager
//
//  Created by wanyc on 13-7-10.
//  Copyright (c) 2013年 Wan Yechao. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>{
    
}

@property (assign) IBOutlet NSWindow *window;

@property (assign) IBOutlet NSTextField *DBPathText;
@property (assign) IBOutlet NSTextField *DBKey;
@property (assign) IBOutlet NSMatrix *actionRadio;
@property (nonatomic,strong) NSString *noticeMessage;
@property (assign) __block IBOutlet NSTextField *noticeText;
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;
@property (assign) IBOutlet NSButton *startButton;


- (IBAction)convertDB:(id)sender;

//showTheAlert
void showAlert(NSString *title,NSString *message);


/**
 * If export fail,delete the temp database
 */
bool deleteDatabase();

//解密数据库
- (void)runDecodeWithDB:(NSString *)path keyword:(NSString *)key;

//加密数据库
- (void)runEncodeWithDB:(NSString *)path keyword:(NSString *)key;


- (void)setUIStatus:(BOOL)isAnimation;

@end
