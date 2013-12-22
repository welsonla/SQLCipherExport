//
//  AppDelegate.m
//  SQLCipherManager
//
//  Created by wanyc on 13-7-10.
//  Copyright (c) 2013年 Wan Yechao. All rights reserved.
//

#import "AppDelegate.h"
#import <sqlite3.h>
#import "Countly.h"

@implementation AppDelegate

@synthesize DBPathText;
@synthesize DBKey;
@synthesize noticeMessage;
@synthesize noticeText;
@synthesize encryptPath;
@synthesize normalPath;
@synthesize progressIndicator;

- (void)dealloc
{
//    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[Countly sharedInstance] startWithAttributes:
    @{
        CountlyAttributesAPIKey: @"f7ba3f4f36fe8d0546557983a7e366d237f6faf2",
        CountlyAttributesHost  : @"http://cloud.count.ly"
    }];
    
    NSApplication *thisApp = [NSApplication sharedApplication];
    [thisApp activateIgnoringOtherApps:YES];
    [self.window makeKeyAndOrderFront:thisApp];
    
    alert = [[NSAlert alloc] init];
    [alert setDelegate:self];
    [alert addButtonWithTitle:@"打开"];
    [alert addButtonWithTitle:@"已阅"];
    
    
 	statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	[statusItem setMenu:statusMenu];
	[statusItem setTitle:@"SQL"];
	[statusItem setHighlightMode:YES];
    [statusItem setTarget:self];
    [statusItem setAction:@selector(bringToFront)];

    
    
    
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"dbkey"]){
        [self.DBKey setStringValue:[[NSUserDefaults standardUserDefaults] objectForKey:@"dbkey"]];
        [self.rememberCheckbox setState:0];
    }
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag{
    //当窗口被关闭时候，点击dock中的图标再次打开
    [self awakeWindow:self];
    return NO;
}

- (IBAction)awakeWindow:(id)sender{
    if (![self.window isVisible]) {
        [self.window makeKeyAndOrderFront:nil];
    }
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}


- (IBAction)bringToFront:(id)sender{
    if (![self.window isVisible]) {
        [self.window makeKeyAndOrderFront:nil];
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    }
}


//进行数据库加密
- (void)runEncodeWithDB:(NSString *)path keyword:(NSString *)key{
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //使用原生的sqlite
        NSString *origin_DB_Path = path;
        
       
        
        
        sqlite3 *convert_DB;
        
        NSString *attachPath = [[NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) objectAtIndex:0]
                                stringByAppendingPathComponent:@"encrypt.db"];;
         self.encryptPath = attachPath;
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:attachPath]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                showAlert(@"提示", @"一个名为'encrypt.db'的数据库已经存在在桌面");
            });
            
            return;
        }
        
        if (sqlite3_open([origin_DB_Path UTF8String], &convert_DB) == SQLITE_OK) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.noticeText setStringValue:@"数据库打开成功"];
            });
            NSLog(@"Database Opened at Time :%@",[NSDate date]);
            
            /**
             * 1.收缩数据库
             */
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.noticeText setStringValue:@"正在进行数据库压缩"];
            });
            sqlite3_exec(convert_DB, [@"vacuum;" UTF8String], NULL, NULL, NULL);
            
            /**
             * 2.生成一个新的加密库
             */
            NSString *sql = [NSString stringWithFormat:@"ATTACH DATABASE '%@' AS encrypted KEY '%@';",attachPath,key];
            
            if(sqlite3_exec(convert_DB, [sql UTF8String] , NULL, NULL, NULL)==SQLITE_OK){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.noticeText setStringValue:@"正在进行加密..."];
                });
                
                if(sqlite3_exec(convert_DB, "SELECT sqlcipher_export('encrypted');", NULL, NULL, NULL)== SQLITE_OK){
                    
                    NSLog(@"导出成功");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.noticeText setStringValue:@"转换成功，正在进行分离"];
                    });
                    /**
                     * 4.分离数据库
                     */
                    if(sqlite3_exec(convert_DB, "DETACH DATABASE encrypted;", NULL, NULL, NULL) == SQLITE_OK){
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"分离成功");
                            [self.noticeText setStringValue:@"加密成功 :)"];
                            [self showFinishAlert:@"加密成功"];
//                            showAlert(@"Encrypt success", @"the database was success export on ~/Desktop/encrypt.db");
                        });
                    }
                    
                }else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"导出失败");
                        [self.noticeText setStringValue:@"导出失败 :("];
                        showAlert(@"Encrypt error", @"Encrypt fail please check your key or your database");
                        deleteDatabase();
                    });
                }
            }else{
                //数据库或者key不正确
                showAlert(@"导出失败", @"导出失败，请检查你的key和数据库是否是加密库");
                deleteDatabase();
            }
            NSLog (@"End database copying at Time: %@",[NSDate date]);
        }
        else {
            showAlert(@"导出失败", @"导出失败，请检查你的key和数据库是否是加密库");
        }
        
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setUIStatus:YES];
        });

        sqlite3_close(convert_DB);
    });
   
}


//进行数据库解密
- (void)runDecodeWithDB:(NSString *)path keyword:(NSString *)key{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //使用原生的sqlite
        NSString *origin_DB_Path = path;
        
        
        
        sqlite3 *convert_DB;
        
        new_db_name = [NSString stringWithFormat:@"DB%@.db",[Utility formatTime:[NSDate date]]];
        NSString *attachPath = [[NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES)
                                 objectAtIndex:0]
                                stringByAppendingPathComponent:new_db_name];
        
        self.normalPath = attachPath;
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:attachPath]) {
            showAlert(@"提示", @"一个名为'developer.db'的数据库已经存在在桌面");
            return;
        }
        
        if (sqlite3_open([origin_DB_Path UTF8String], &convert_DB) == SQLITE_OK) {
            
            const char *dbkey = [key UTF8String];
            
            sqlite3_key(convert_DB, dbkey, strlen(dbkey));
            
            NSLog(@"Database Opened at Time :%@",[NSDate date]);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.noticeText setStringValue:@"数据库打开成功"];
            });
            
            /**
             * 1.收缩数据库
             */
            sqlite3_exec(convert_DB, [@"vacuum;" UTF8String], NULL, NULL, NULL);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.noticeText setStringValue:@"正在进行优化"];
            });
            /**
             * 2.生成一个新的非加密库
             */
            NSString *sql = [NSString stringWithFormat:@"ATTACH DATABASE '%@' AS encrypted KEY '';",attachPath];
            
            if(sqlite3_exec(convert_DB, [sql UTF8String] , NULL, NULL, NULL)==SQLITE_OK){
                
                if(sqlite3_exec(convert_DB, "SELECT sqlcipher_export('encrypted');", NULL, NULL, NULL)== SQLITE_OK){
                    NSLog(@"导出成功");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.noticeText setStringValue:@"导出成功"];
                    });
                    
                    /**
                     * 4.分离数据库
                     */
                    if(sqlite3_exec(convert_DB, "DETACH DATABASE encrypted;", NULL, NULL, NULL) == SQLITE_OK){
                        NSLog(@"分离成功");
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                             [self.noticeText setStringValue:@"解密成功 :)"];
                             [self.progressIndicator setHidden:YES];
                             [self showFinishAlert:@"解密成功"];
                           
                        });
                       
                    }
                    
                }else{
                    //导出过程中发生错误
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"导出失败");
                        [self.noticeText setStringValue:@"导出失败 :("];
                        showAlert(@"导出失败", @"导出失败，请检查你的key和数据库是否是加密库");
                    });
                   
                    deleteDatabase();
                }
            }else{
                //如果路径或者key是错误的
                dispatch_async(dispatch_get_main_queue(), ^{
                   showAlert(@"导出失败", @"导出失败，请检查你的key和数据库是否是加密库");
                });
                deleteDatabase();
            }
            NSLog (@"End database copying at Time: %@",[NSDate date]);
            
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                showAlert(@"export error", @"export fail please check your key or your database");
            });
        }
        
        sqlite3_close(convert_DB);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setUIStatus:YES];
        });

    });
    
   
}

/**
 *	存储DBkey到UserDefault中
 *
 *	@param	sender	NSButton
 */
- (IBAction)rememberKey:(id)sender {
    NSButton *button  = sender;
    if(button.state && DBKey.stringValue.length>0){
        NSString *stringOfDBKey = [self.DBKey stringValue];
        [[NSUserDefaults standardUserDefaults] setObject:stringOfDBKey forKey:@"dbkey"];
        
    }else{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"dbkey"];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}



/**
 *	转换button点击事件
 *
 *	@param	sender	NSButton
 */
- (IBAction)convertDB:(id)sender {

    if (DBPathText.stringValue.length==0) {
        showAlert(@"提示", @"Drap your Sqlite to the first input");
        return ;
    }
    
    if (DBKey.stringValue.length==0) {
        showAlert(@"the key was invalid", @"key太短了");
        return;
    }
    
    NSString *dbpath = DBPathText.stringValue;
    NSString *key = DBKey.stringValue;
    
    //检查是否要存储key
    [self rememberKey:self.rememberCheckbox];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dbpath]) {
        showAlert(@"notice", @"I could not found the sqlite at this path");
        return;
    }else{
        
        /**
         *判断是加密还是解密
         * 0:解密
         * 1:加密
         */
        NSInteger tag = self.cryptSegment.selectedSegment;
        
        
        if (tag == 0) {
            [self runDecodeWithDB:dbpath keyword:key];
        }else{
            [self runEncodeWithDB:dbpath keyword:key];
        }
    }
    
    [self setUIStatus:NO];

}


#pragma mark -
#pragma mark - Common function to call NSAlert
void showAlert(NSString *title,NSString *message){
    [[NSAlert alertWithMessageText:title defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@",message] runModal];
}

- (void)showFinishAlert:(NSString *)message{
    [alert setMessageText:message];
    [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(didAlert:selectedIndex:withContent:) contextInfo:nil];
}


- (void)didAlert:(NSAlert *)alertView selectedIndex:(int)index withContent:(void *)content{
    if (index==1000) {
        if(self.cryptSegment.selectedSegment==0){
             NSLog(@"normal:%@",normalPath);
           [Utility openInFinder:self.normalPath];
          
        }else{
            NSLog(@"encrypt:%@",encryptPath);
           [Utility openInFinder:self.encryptPath];
           
        }
    }
}


#pragma mark -
#pragma mark - If Export fail delete the failed database
bool deleteDatabase(){
    NSFileManager *fmg = [NSFileManager defaultManager];
    NSString *failedDB = [[NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) 
																							objectAtIndex:0] stringByAppendingPathComponent:@"developer.db"];
    
    if ([fmg removeItemAtPath:failedDB error:nil]) {
        return true;
    }else{
        return false;
    }
}


- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard type:(NSString *)type{
    return YES;
}

- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard type:(NSString *)type{
    return YES;
}

#pragma mark -
#pragma mark - set UI Status
/**
 *	@brief	设置界面的UI状态
 *
 *	@param 	isAnimation BOOL value
 */
- (void)setUIStatus:(BOOL)isAnimation
{
    
   
    if (isAnimation) {
        [self.startButton setEnabled:YES];
        [self.startButton setStringValue:@"go !"];
        [self.DBKey setEnabled:YES];
        [self.DBPathText setEnabled:YES];
        [self.progressIndicator stopAnimation:self];
        [self.progressIndicator setHidden:YES];
    }else{
        //开始动画的时候，将UI状态置为不可编辑
        [self.startButton setEnabled:NO];
        [self.startButton setStringValue:@"waiting..."];
        [self.DBKey setEnabled:NO];
        [self.DBPathText setEnabled:NO];
        [self.progressIndicator setHidden:NO];
        [self.progressIndicator startAnimation:self];
    }
}



- (IBAction)showProjectWebsite:(id)sender{
    [[NSWorkspace sharedWorkspace] openURL:
     [NSURL URLWithString:@"https://github.com/welsonla/SQLCipherExport"]];
}



@end
