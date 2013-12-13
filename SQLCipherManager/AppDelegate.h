//
//  AppDelegate.h
//  SQLCipherManager
//
//  Created by wanyc on 13-7-10.
//  Copyright (c) 2013年 Wan Yechao. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Utility.h"

@interface AppDelegate : NSObject <NSApplicationDelegate,NSAlertDelegate>{
    IBOutlet NSMenu *statusMenu;
    NSStatusItem *statusItem;
    NSString *new_db_name;
    
    NSString *encryptPath;
    NSString *normalPath;
    NSAlert *alert;
}

@property (assign) IBOutlet NSWindow *window;

@property (assign) IBOutlet NSTextField *DBPathText;
@property (assign) IBOutlet NSTextField *DBKey;
@property (nonatomic,strong) NSString *noticeMessage;
@property (assign) __block IBOutlet NSTextField *noticeText;
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;
@property (assign) IBOutlet NSButton *startButton;

@property (assign) IBOutlet NSButton *rememberCheckbox;
@property (assign) IBOutlet NSSegmentedControl *cryptSegment;


@property (strong,nonatomic) NSString *encryptPath;
@property (strong,nonatomic) NSString *normalPath;


- (IBAction)rememberKey:(id)sender;

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

- (IBAction)awakeWindow:(id)sender;

- (IBAction)showProjectWebsite:(id)sender;

- (void)showFinishAlert:(NSString *)message;

@end
