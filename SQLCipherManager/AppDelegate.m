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

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{

}


void *runDecode(NSString *path,NSString *keyword){
    //使用原生的sqlite
    NSString *origin_DB_Path = path;
    
    sqlite3 *convert_DB;
    
    NSString *attachPath = [[NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) objectAtIndex:0]
                            stringByAppendingPathComponent:@"encrypt.db"];;
    
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:attachPath]) {
        showAlert(@"Notice", @"a database named 'developer.db' is already on the Desktop");
        return false;
    }
    
    if (sqlite3_open([origin_DB_Path UTF8String], &convert_DB) == SQLITE_OK) {
        
        NSLog(@"Database Opened at Time :%@",[NSDate date]);
        
        /**
         * 1.收缩数据库
         */
        sqlite3_exec(convert_DB, [@"vacuum;" UTF8String], NULL, NULL, NULL);
        
        /**
         * 2.生成一个新的加密库
         */
        NSString *sql = [NSString stringWithFormat:@"ATTACH DATABASE '%@' AS encrypted KEY '%@';",attachPath,keyword];
        
        if(sqlite3_exec(convert_DB, [sql UTF8String] , NULL, NULL, NULL)==SQLITE_OK){
            
            if(sqlite3_exec(convert_DB, "SELECT sqlcipher_export('encrypted');", NULL, NULL, NULL)== SQLITE_OK){
                NSLog(@"导出成功");
                
                /**
                 * 4.分离数据库
                 */
                if(sqlite3_exec(convert_DB, "DETACH DATABASE encrypted;", NULL, NULL, NULL) == SQLITE_OK){
                    NSLog(@"分离成功");
                    showAlert(@"Encrypt success", @"the database was success export on ~/Desktop/encrypt.db");
                }
                
            }else{
                
                NSLog(@"导出失败");
                showAlert(@"Encrypt error", @"Encrypt fail please check your key or your database");
                deleteDatabase();
            }
        }else{
            showAlert(@"export error", @"export fail please check your key or your database");
            deleteDatabase();
        }
        NSLog (@"End database copying at Time: %@",[NSDate date]);
        sqlite3_close(convert_DB);
    }
    else {
        showAlert(@"export error", @"export fail please check your key or your database");
        sqlite3_close(convert_DB);
    }

}


void *runEncode(NSString *path,NSString *keyword)
{

        //使用原生的sqlite
        NSString *origin_DB_Path = path;
    
        sqlite3 *convert_DB;
    
        NSString *attachPath = [[NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) objectAtIndex:0]
                                 stringByAppendingPathComponent:@"developer.db"];;
    
  
        if ([[NSFileManager defaultManager] fileExistsAtPath:attachPath]) {
            showAlert(@"Notice", @"a database named 'developer.db' is already on the Desktop");
            return false;
        }
    
        if (sqlite3_open([origin_DB_Path UTF8String], &convert_DB) == SQLITE_OK) {
            
            const char *dbkey = [keyword UTF8String];
            
            sqlite3_key(convert_DB, dbkey, strlen(dbkey));
            
            NSLog(@"Database Opened at Time :%@",[NSDate date]);
           
            
            /**
             * 1.收缩数据库
             */
            sqlite3_exec(convert_DB, [@"vacuum;" UTF8String], NULL, NULL, NULL);
            
            /**
             * 2.生成一个新的加密库
             */
            NSString *sql = [NSString stringWithFormat:@"ATTACH DATABASE '%@' AS encrypted KEY '';",attachPath];
            
            if(sqlite3_exec(convert_DB, [sql UTF8String] , NULL, NULL, NULL)==SQLITE_OK){
       
                if(sqlite3_exec(convert_DB, "SELECT sqlcipher_export('encrypted');", NULL, NULL, NULL)== SQLITE_OK){
                    NSLog(@"导出成功");
                    
                    /**
                     * 4.分离数据库
                     */
                    if(sqlite3_exec(convert_DB, "DETACH DATABASE encrypted;", NULL, NULL, NULL) == SQLITE_OK){
                        NSLog(@"分离成功");
                        showAlert(@"export success", @"the database was success export on ~/Desktop/developer.db");
                    }

                }else{
                    
                    NSLog(@"导出失败");
                    showAlert(@"export error", @"export fail please check your key or your database");
                    deleteDatabase();
                }
            }else{
                showAlert(@"export error", @"export fail please check your key or your database");
                deleteDatabase();
            }
            NSLog (@"End database copying at Time: %@",[NSDate date]);
            sqlite3_close(convert_DB);

            
            
        }
        else {
            showAlert(@"export error", @"export fail please check your key or your database");
            sqlite3_close(convert_DB);
        }
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
            runEncode(dbpath, key);
        }else{
            runDecode(dbpath, key);
        }
    }
  
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

@end
