//
//  FileDialog.swift
//  nmp
//
//  Created by C. Wiggins on 15/11/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import Cocoa

func open() -> [URL?] {
    let dialog = NSOpenPanel()
    
    dialog.title = "Open one or more audio files or directories to queue"
    dialog.showsResizeIndicator = true
    dialog.showsHiddenFiles = false
    dialog.canChooseDirectories = true
    dialog.canCreateDirectories = false
    dialog.allowsMultipleSelection = true
    dialog.allowedFileTypes = audioFileTypes
    
    let response = dialog.runModal()
    
    if response.rawValue == NSApplication.ModalResponse.OK.rawValue {
        for url in dialog.urls {
            saveURLToBookmarks(url: url, userDefaults: UserDefaults.standard)
        }
    }
    
    return dialog.urls
}

func saveURLToBookmarks(url: URL, userDefaults: UserDefaults) {
    do {
        let bookmark = try url.bookmarkData(options: .securityScopeAllowOnlyReadAccess, includingResourceValuesForKeys: nil, relativeTo: nil)
        userDefaults.set(bookmark, forKey: urlBookmarkKey)
    } catch let error {
        print("Error saving bookmark: \(error.localizedDescription)")
    }
}

func loadBookmarkData() {
    if let bookmarkData = UserDefaults.standard.object(forKey: urlBookmarkKey) as? Data {
        do {
            var dataIsStale = false
            let url = try URL(resolvingBookmarkData: bookmarkData, options: .withoutUI, relativeTo: nil, bookmarkDataIsStale: &dataIsStale)
            _ = url.startAccessingSecurityScopedResource()
        } catch let error {
            print("Error loading bookmark: \(error.localizedDescription)")
        }
    }
}

func openMedia() -> [URL?] {
    return sortUrls(urls: recurseSubdirectories(urls: open()))
}

func isDirectory(path: String) -> Bool {
    var isDir: ObjCBool = false
    
    if FileManager.default.fileExists(atPath: path, isDirectory: &isDir) {
        return isDir.boolValue
    }
    
    return false
}


func ls(path: String) -> [String] {
    var ret: [String] = []
    
    do {
        ret = try FileManager.default.contentsOfDirectory(atPath: path)
    } catch let error {
        print(error.localizedDescription)
    }
    
    return ret
}

func recurseSubdirectory(url: URL) -> [URL] {
    var ret: [URL] = []
    let path = url.path
    
    for obj in ls(path: path) {
        ret.append(URL(fileURLWithPath: url.path + pathSep + obj))
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

func fileDisplayName(forPath path: String) -> String {
    return FileManager.default.displayName(atPath: path)
}

func getCoverArt(fromDirectory dir: URL) -> URL? {
    if dir.hasDirectoryPath {
        do {
            let dirPath = dir.path
            let contents = try FileManager.default.contentsOfDirectory(atPath: dirPath)
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
