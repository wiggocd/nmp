//
//  Library.swift
//  nmp
//
//  Created by C. Wiggins on 21/11/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import Cocoa
import AVFoundation

let urlBookmarkKey = "Bookmark"
let audioFileTypes = ["wav", "mp2", "mp3", "m4a"]
let imageFileTypes = ["jpg", "jpeg", "png"]
let coverArtKeywords = ["cover", "front", "folder"]
let pathSep = "/"
let extSep = "."
let alpha = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
let alphaReverse = alpha.reversed()
let REORDER_PASTEBOARD_TYPE = NSPasteboard.PasteboardType((Bundle.main.bundleIdentifier ?? "")+".item")
let FILENAMES_PASTEBOARD_TYPE = NSPasteboard.PasteboardType.fileURL
let playlistPasteboardTypes = [REORDER_PASTEBOARD_TYPE, FILENAMES_PASTEBOARD_TYPE]

class AudioMetadata {
    var title: String = " "
    var artist: String = " "
    var album: String = " "
    var artwork: CGImage!
    
    init(forURL url: URL) {
        let metadataList = AVAsset(url: url).commonMetadata
        for item in metadataList {
            let commonKey = item.commonKey?.rawValue ?? ""
            let stringValue = item.stringValue ?? ""
            
            switch commonKey {
            case "title":
                self.title = stringValue
            case "artist":
                self.artist = stringValue
            case "albumName":
                self.album = stringValue
            case "artwork":
                self.artwork = CGImage(jpegDataProviderSource: CGDataProvider(data: item.dataValue! as CFData)!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent(rawValue: 32)!)
            default:
                break
            }
        }
    }
    
    func detailsString() -> String {
        if self.artist != " " {
            if self.album != " " {
                return self.artist + " - " + self.album
            }
            return self.artist
        }
        return " "
    }
}

class PlaylistItem: NSObject {
    var url: URL
    var trackIndex: Int
    var label: String!
    var metadata: AudioMetadata {
        didSet {
            label = playlistLabel()
        }
    }
    
    init(url: URL, trackIndex: Int = 0) {
        self.url = url
        self.trackIndex = trackIndex
        self.metadata = AudioMetadata(forURL: url)
        
        super.init()
        self.label = self.playlistLabel()
    }
    
    func playlistLabel() -> String {
        let displayIndex = self.trackIndex + 1
        if self.metadata.title != " " {
            if self.metadata.artist != " " {
                return "\(displayIndex). " + self.metadata.artist + " - " + self.metadata.title
            }
            return "\(displayIndex). \(self.metadata.title)"
        }
        return "\(displayIndex). \(fileDisplayName(forPath: self.url.path))"
    }
}

enum PlayerState {
    case idle
    case playing
    case paused
}


func filterToSupportedOnly(urls: [URL?]) -> [URL?] {
    var ret: [URL] = []
    
    for url in urls {
        if audioFileTypes.contains(url!.pathExtension) {
            ret.append(url!)
        }
    }
    
    return ret
}

func sortUrls(urls: [URL?]) -> [URL?] {
    var paths: [String] = []
    var ret: [URL?] = []
    
    for url in urls {
        paths.append(url!.path)
    }
    
    for path in paths.sorted() {
        ret.append(URL(fileURLWithPath: path))
    }
    
    return ret
}

func to_hhmmss(seconds: Double) -> String {
    var timeString = "00:00"
    
    if seconds.isNormal {
        var s = Int(seconds)
        var m = Int(s / 60)
        s = s % 60
        let h = Int(m / 60)
        m = m % 60
        
        var string_m = String(m)
        var string_s = String(s)
        var string_h: String!
        
        if h != 0 {
            string_h = String(h)
        }
        
        if string_m.count == 1 {
            string_m = "0"+string_m
        }
        
        if string_s.count == 1 {
            string_s = "0"+string_s
        }
        
        timeString = string_m + ":" + string_s
        if string_h != nil {
            timeString = string_h + ":" + timeString
        }
    }
    
    return timeString
}

func isCommandModifierFlag(flags: NSEvent.ModifierFlags) -> Bool {
    return flags.contains(.command) &&
    !flags.contains(.control) &&
    !flags.contains(.function) &&
    !flags.contains(.help) &&
    !flags.contains(.option) &&
    !flags.contains(.shift)
}
