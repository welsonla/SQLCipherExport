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

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{

}

NSString *runCommand(NSString *path,NSString *keyword)
{
//    NSTask *task;
//    task = [[NSTask alloc] init];
//    [task setLaunchPath: @"/bin/sh"];
//    
//    NSArray *arguments = [NSArray arrayWithObjects:
//                          @"-c" ,
//                          [NSString stringWithFormat:@"sqlcipher %@", path],
//                          nil];
////    NSLog(@"run command: %@",commandToRun);
//    [task setArguments: arguments];
//    
//    NSPipe *pipe;
//    pipe = [NSPipe pipe];
//    [task setStandardOutput: pipe];
//    
//    NSFileHandle *file;
//    file = [pipe fileHandleForReading];
//    
//    [task launch];
//    
//    NSData *data;
//    data = [file readDataToEndOfFile];
//    
//    NSString *output = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
//    return output;
    
    
    /////
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        //使用原生的sqlite
        NSString *origin_DB_Path = path;
        
        sqlite3 *convert_DB;
        
        NSString *attachPath = [[NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) objectAtIndex:0]
                                 stringByAppendingPathComponent:@"developer.db"];;
    
  
    
    
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
                    }
                    
                    [[NSAlert alertWithMessageText:@"export success"
                                     defaultButton:@"OK"
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@"the database was success export on ~/Desktop/developer.db"]
                     runModal];
                    
                }else{
                    
                    NSLog(@"导出失败");
                    [[NSAlert alertWithMessageText:@"export error"
                                     defaultButton:@"I know"
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@"export fail please check your key or your database"] runModal];
                    
                    
                }
            }
            
            NSLog (@"End database copying at Time: %@",[NSDate date]);
            sqlite3_close(convert_DB);
            
            
        }
        else {
            [[NSAlert alertWithMessageText:@"export error"
                             defaultButton:@"I know"
                           alternateButton:nil
                               otherButton:nil
                 informativeTextWithFormat:@"export fail please check your key or your database"] runModal];
            sqlite3_close(convert_DB);
        }
        
//    });
    /////
    
    return nil;
}
- (IBAction)convertDB:(id)sender {
    if (DBPathText.stringValue.length==0) {
        [[NSAlert alertWithMessageText:@"could not found the database"
                         defaultButton:@"OK,I know"
                       alternateButton:nil
                           otherButton:nil
             informativeTextWithFormat:@"Drap your Sqlite to the first input"] runModal];
        return ;
    }
    
    if (DBKey.stringValue.length==0) {
        [NSAlert alertWithMessageText:@"the key was invalid" defaultButton:@"OK,I know"
                      alternateButton:nil
                          otherButton:nil
            informativeTextWithFormat:@"Please check your database key!"];
        return;
    }
    
    NSString *dbpath = DBPathText.stringValue;
    NSString *key = DBKey.stringValue;
    
    
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dbpath]) {
        [[NSAlert alertWithMessageText:@"notice"
                         defaultButton:@"OK"
                       alternateButton:nil
                           otherButton:nil
             informativeTextWithFormat:@"I could not found the sqlite at this path"]
         runModal];
        
        return;
    }else{
        runCommand(dbpath, key);
    }
  
}
@end
