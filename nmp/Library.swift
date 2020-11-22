//
//  Library.swift
//  nmp
//
//  Created by Kate Wiggins on 21/11/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import AVFoundation

let progName = "nmp"
let allowedFileTypes = ["wav", "mp2", "mp3", "m4a"]
let pathSep = "/"
let alpha = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
let alphaReverse = alpha.reversed()

class AudioMetadata {
    var title: String = ""
    var artist: String = ""
    var album: String = ""
    var artwork: CGImage!
    
    init(playerItem: AVPlayerItem) {
        let metadataList = playerItem.asset.commonMetadata
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
                ()
            }
        }
    }
    
    func detailsString() -> String {
        return artist + " - " + album
    }
}

func filterToSupportedOnly(urls: [URL?]) -> [URL?] {
    var ret: [URL] = []
    
    for url in urls {
        if allowedFileTypes.contains(url!.pathExtension) {
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
    
    var timeString = string_m + ":" + string_s
    if string_h != nil {
        timeString = string_h + ":" + timeString
    }
    
    return timeString
}
