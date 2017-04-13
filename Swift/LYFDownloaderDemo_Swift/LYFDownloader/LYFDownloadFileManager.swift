//
//  LYFDownloadFileManager.swift
//  LYFDownloaderDemo_Swift
//
//  Created by 罗元丰 on 2017/3/23.
//  Copyright © 2017年 罗元丰. All rights reserved.
//

import UIKit

class LYFDownloadFileManager: NSObject {
    
    private static var fm = FileManager.default
    
    static func subPath(atPath: String!) -> Array<String> {
        return fm.subpaths(atPath: atPath)!
    }
    
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
    
}
