//
//  Created by 罗元丰 on 2017/3/3.
//  Copyright © 2017年 罗元丰. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LYFDownloadFileManager : NSObject

+ (NSArray *)subpathOfPath:(NSString *)path;

+ (BOOL)moveFileFromPath:(NSString *)srcPath
                  toPath:(NSString *)desPath
                fileName:(NSString *)fileName
                   error:(NSError **)error;

+ (BOOL)writeContent:(NSData *)data
              toPath:(NSString *)desPath
            fileName:(NSString *)fileName
      createNotExist:(BOOL)createNotExist
               error:(NSError **)error;

+ (BOOL)readFileFromPath:(NSString *)targetPath
              completion:(void(^)(NSData *data))completion;

+ (BOOL)deleteFileAtPath:(NSString *)path;

@end
