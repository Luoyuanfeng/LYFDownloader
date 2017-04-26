//
//  LYFDownloadFileManager.swift
//  LYFDownloaderDemo_Swift
//
//  Created by 罗元丰 on 2017/3/23.
//  Copyright © 2017年 罗元丰. All rights reserved.
//

import UIKit

class LYFDownloadFileManager: NSObject {
    
    //MARK: fileManager
    private static var fm = FileManager.default
    
    //MARK: - 获取子目录
    static func subPath(atPath: String!) -> Array<String> {
        return fm.subpaths(atPath: atPath)!
    }
    
    //MARK: - 移动文件
    static func moveFile(from: String!, to: String!, fileName: String!) -> Bool {
        
        if fm.fileExists(atPath: from) {
            if !fm.fileExists(atPath: to) {
                
                do {
                    try fm.createDirectory(atPath: to, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    return false
                }
                
                do {
                    try fm.moveItem(atPath: from, toPath: String.init(format: "%@/%@", to, fileName))
                } catch {
                    return false
                }
            }
            return true
        }
        return false
    }
    
    //MARK: - 写文件
    static func writeFile(content: Data!, to: String!, fileName: String!, canCreate: Bool) -> Bool {
        let filePath = to.appending(String.init(format: "/%@", fileName))
        let fileNotExist = fm.fileExists(atPath: filePath)
        
        if fileNotExist && !canCreate {
            print("can't create dir when file does not exist at %@", filePath)
            return false
        }
        
        if fm.fileExists(atPath: to) {
            do {
                try fm.createDirectory(atPath: to, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return false
            }
        }
        
        if fileNotExist {
            return fm.createFile(atPath: filePath, contents: content, attributes: nil)
        }
        
        do {
            try fm.removeItem(atPath: filePath)
        } catch {
            return false
        }
        return fm.createFile(atPath: filePath, contents: content, attributes: nil)
    }
    
    //MARK: - 读取文件
    static func readFile(from: String!) -> Data? {
        return fm.contents(atPath: from)
    }
    
    //MARK: - 删除文件
    static func deleteFile(atPath: String!) -> Bool {
        do {
            try fm.removeItem(atPath: atPath)
        } catch {
            return false
        }
        return true;
    }
}
