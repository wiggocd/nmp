//
//  FileDialog.swift
//  nmp
//
//  Created by Kate Wiggins on 15/11/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import Cocoa

let fileManager = FileManager()

func open() -> [URL?] {
    let dialog = NSOpenPanel()
    
    dialog.title = "Open one or more audio files or directories to queue"
    dialog.showsResizeIndicator = true
    dialog.showsHiddenFiles = false
    dialog.canChooseDirectories = true
    dialog.canCreateDirectories = false
    dialog.allowsMultipleSelection = true
    dialog.allowedFileTypes = audioFileTypes
    
    dialog.runModal()
    
    return dialog.urls
}

func openMedia() -> [URL?] {
    return sortUrls(urls: recurseSubdirectories(urls: open()))
}

func isDirectory(path: String) -> Bool {
    var isDir: ObjCBool = false
    
    if fileManager.fileExists(atPath: path, isDirectory: &isDir) {
        return isDir.boolValue
    }
    
    return false
}


func ls(path: String) -> [String] {
    var ret: [String] = []
    
    do {
        ret = try fileManager.contentsOfDirectory(atPath: path)
    } catch let error {
        print(error.localizedDescription)
    }
    
    return ret
}

func recurseSubdirectory(url: URL) -> [URL] {
    var ret: [URL] = []
    let path = url.path
    
    for obj in ls(path: path) {
        if isDirectory(path: obj) {
            print("Is directory")
            ret.append(contentsOf: recurseSubdirectory(url: URL(fileURLWithPath: obj)))
        } else {
            ret.append(URL(fileURLWithPath: url.path + pathSep + obj))
        }
    }
    
    return ret
}


func recurseSubdirectories(urls: [URL?]) -> [URL?] {
    var ret: [URL?] = []
    
    for url in urls {
        if isDirectory(path: url!.path) {
            ret.append(contentsOf: recurseSubdirectory(url: url!))
        } else {
            ret.append(url)
        }
    }
    
    return ret
}

func fileDisplayName(path: String) -> String {
    return fileManager.displayName(atPath: path)
}

func getCoverArt(fromDirectory dir: URL) -> URL? {
    if dir.hasDirectoryPath {
        do {
            let dirPath = dir.path
            let contents = try fileManager.contentsOfDirectory(atPath: dirPath)
            var images: [String] = []
            
            for relativePath in contents {
                let split = relativePath.split(separator: ".")
                if imageFileTypes.contains(split[split.count-1].lowercased()) {
                    images.append(relativePath)
                }
            }
            
            for relativePath in images {
                let lower = relativePath.lowercased()
                for keyword in coverArtKeywords {
                    if lower.contains(keyword) {
                        return URL(fileURLWithPath: dirPath+pathSep+relativePath)
                    }
                }
            }
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    return nil
}
