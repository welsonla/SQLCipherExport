//
//  AppDelegate.h
//  SQLCipherManager
//
//  Created by wanyc on 13-7-10.
//  Copyright (c) 2013年 Wan Yechao. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (assign) IBOutlet NSTextField *DBPathText;
@property (assign) IBOutlet NSTextField *DBKey;

- (IBAction)convertDB:(id)sender;

//showTheAlert
void showAlert(NSString *title,NSString *message);


/**
 * If export fail,delete the temp database
 */
bool deleteDatabase();

@end
