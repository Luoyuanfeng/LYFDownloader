//
//  Created by 罗元丰 on 2017/3/3.
//  Copyright © 2017年 罗元丰. All rights reserved.
//

#import "LYFDownloadFileManager.h"

static NSFileManager *fm;

@implementation LYFDownloadFileManager

+ (void)initialize
{
    fm = [NSFileManager defaultManager];
}

+ (NSArray *)subpathOfPath:(NSString *)path
{
    if (path) {
        return [fm subpathsAtPath:path];
    }
    return NSArray.new;
}

+ (BOOL)moveFileFromPath:(NSString *)srcPath
                  toPath:(NSString *)desPath
                fileName:(NSString *)fileName
                   error:(NSError *__autoreleasing *)error
{
    if (!srcPath || !desPath || !fileName) {
#if DEBUG
        NSLog(@"移动文件参数有误");
#endif
        return NO;
    }
    
    if ([fm fileExistsAtPath:srcPath]) {
        
        if (![fm fileExistsAtPath:desPath]) {
            
            [fm createDirectoryAtPath:desPath withIntermediateDirectories:YES attributes:nil error:error];
        }
        
        NSString *toPath = [NSString stringWithFormat:@"%@/%@", desPath, fileName];
        [fm moveItemAtPath:srcPath toPath:toPath error:error];
        
    } else {
#if DEBUG
        NSLog(@"要移动的源文件不存在");
#endif
        return NO;
    }
    return YES;
}

+ (BOOL)writeContent:(NSData *)data
              toPath:(NSString *)desPath
            fileName:(NSString *)fileName
      createNotExist:(BOOL)createNotExist
               error:(NSError **)error;
{
    NSString *filePath = [desPath stringByAppendingPathComponent:fileName];
    
    BOOL fileNotExist = ![fm fileExistsAtPath:filePath];
    if (!createNotExist && fileNotExist) {
#if DEBUG
        NSLog(@"要写入的文件不存在");
#endif
        return NO;
    }
    
    if (![fm fileExistsAtPath:desPath]) {
        [fm createDirectoryAtPath:desPath withIntermediateDirectories:YES attributes:nil error:error];
    }
    
    if (fileNotExist) {
        return [fm createFileAtPath:filePath contents:data attributes:nil];
    } else {
        [fm removeItemAtPath:filePath error:error];
        return [fm createFileAtPath:filePath contents:data attributes:nil];
    }
}

+ (BOOL)readFileFromPath:(NSString *)targetPath completion:(void (^)(NSData *))completion
{
    if (!targetPath) {
#if DEBUG
        NSLog(@"要读取的文件不存在");
#endif
        return NO;
    }
    
    dispatch_queue_t readQueue = dispatch_queue_create("jjz_read", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(readQueue, ^{
        NSData *resultData = [fm contentsAtPath:targetPath];
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(resultData);
            });
        }
    });
    
    return YES;
}

+ (BOOL)deleteFileAtPath:(NSString *)path
{
    if (path) {
        return [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    return NO;
}

@end
