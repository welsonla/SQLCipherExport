//
//  AppDelegate.m
//  SQLCipherManager
//
//  Created by wanyc on 13-7-10.
//  Copyright (c) 2013年 Wan Yechao. All rights reserved.
//

#import "AppDelegate.h"
#import <sqlite3.h>

@implementation AppDelegate

@synthesize DBPathText;
@synthesize DBKey;
@synthesize actionRadio;
@synthesize noticeMessage;
@synthesize noticeText;
@synthesize progressIndicator;

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"dbkey"]){
        [self.DBKey setStringValue:[[NSUserDefaults standardUserDefaults] objectForKey:@"dbkey"]];
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
        
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:attachPath]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                showAlert(@"Notice", @"a database named 'developer.db' is already on the Desktop");
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
                            showAlert(@"Encrypt success", @"the database was success export on ~/Desktop/encrypt.db");
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
                showAlert(@"export error", @"export fail please check your key or your database");
                deleteDatabase();
            }
            NSLog (@"End database copying at Time: %@",[NSDate date]);
        }
        else {
            showAlert(@"export error", @"export fail please check your key or your database");
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
        
        NSString *dbname = [NSString stringWithFormat:@"developer%.0f.db",[[NSDate date] timeIntervalSince1970]];
        NSString *attachPath = [[NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES)
                                 objectAtIndex:0]
                                stringByAppendingPathComponent:dbname];
        
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:attachPath]) {
            showAlert(@"Notice", @"a database named 'developer.db' is already on the Desktop");
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
                             showAlert(@"export success", @"the database was success export on ~/Desktop/developer.db");
                        });
                       
                    }
                    
                }else{
                    //导出过程中发生错误
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"导出失败");
                        [self.noticeText setStringValue:@"导出失败 :("];
                        showAlert(@"export error", @"export fail please check your key or your database");
                    });
                   
                    deleteDatabase();
                }
            }else{
                //如果路径或者key是错误的
                dispatch_async(dispatch_get_main_queue(), ^{
                    showAlert(@"export error", @"export fail please check your key or your database");
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


- (IBAction)convertDB:(id)sender {

    
    
    if (DBPathText.stringValue.length==0) {
        showAlert(@"could not found the database", @"Drap your Sqlite to the first input");
        return ;
    }
    
    if (DBKey.stringValue.length==0) {
        showAlert(@"the key was invalid", @"Please check your database key!");
        return;
    }
    
    NSString *dbpath = DBPathText.stringValue;
    NSString *key = DBKey.stringValue;
    
    
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dbpath]) {
        showAlert(@"notice", @"I could not found the sqlite at this path");
        return;
    }else{
        
        /**
         *判断是加密还是解密
         * 0:解密
         * 1:加密
         */
         NSInteger tag = self.actionRadio.selectedTag;
        
        
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

@end
