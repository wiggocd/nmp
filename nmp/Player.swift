//
//  Player.swift
//  nmp
//
//  Created by C. Wiggins on 14/11/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import AVFoundation

class AudioPlayer: NSObject, AVAudioPlayerDelegate {
    let application = Application.shared as? Application
    
    private var notificationCenter: NotificationCenter!
    var player: AVAudioPlayer!
    var playlist: [URL] = [] {
        didSet {
            self.notificationCenter.post(name: .playlistChanged, object: nil)
            var strings: [String] = []
            for item in playlist {
                strings.append(item.absoluteString)
            }
            self.application?.userDefaults.set(strings, forKey: "Playlist")
        }
    }
    
    var trackIndex: Int! {
        didSet {
            seekTrack(index: trackIndex)
            self.application?.userDefaults.set(trackIndex, forKey: "TrackIndex")
        }
    }
    
    var metadata: AudioMetadata!
    var lastIndex = 0
    var currentUrl: URL! {
        didSet {
            if currentUrl == nil {
                self.player = nil
            } else {
                do {
                    self.player = try AVAudioPlayer(contentsOf: currentUrl)
                    self.player.volume = self.volume
                    self.mediaChanged()
                } catch let error {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    var position: TimeInterval {
        get {
            if self.player != nil {
                return self.player.currentTime
            } else {
                return 0.0
            }
        }
    }
    
    var volume: Float = 1.0 {
        didSet {
            if self.player != nil {
                self.player.volume = volume
            }
        }
    }
    
    private var lastVolume: Float = 1.0
    var muted = false
    
    @Published var state = PlayerState.idle {
        didSet { self.stateChanged() }
    }
    
    init(notificationCenter: NotificationCenter = .default) {
        super.init()
        self.notificationCenter = notificationCenter
        
        if self.loadPlaylistFromDefaults() {
            self.loadTrackIndexFromDefaults()
        }
        
        if self.trackIndex == nil {
            self.trackIndex = 0
        }
    }
    
    func loadPlaylistFromDefaults() -> Bool {
        self.loadBookmarkData()
        let playlistData = self.application?.userDefaults.array(forKey: "Playlist") as? [String]
        var urls: [URL] = []
        
        if playlistData != nil {
            if playlistData!.count > 0 {
                for item in playlistData! {
                    if let url = URL(string: item) {
                        _ = url.startAccessingSecurityScopedResource()
                        urls.append(url)
                    }
                }
            }
        }
        
        if urls.count > 0 {
            self.addMedia(urls: urls, updateIndexIfNew: false, shouldPlay: false)
            return true
        } else {
            return false
        }
    }
    
    func loadTrackIndexFromDefaults() {
        if let data = self.application?.userDefaults.integer(forKey: "TrackIndex") {
            self.trackIndex = data
        }
    }
    
    func clearPlaylistDefaults() {
        self.application?.userDefaults.removeObject(forKey: "TrackIndex")
        self.application?.userDefaults.removeObject(forKey: "Playlist")
    }
    
    func addMedia(urls: [URL?], updateIndexIfNew: Bool, shouldPlay: Bool) {
        if urls.count > 0 {
            for url in urls {
                if url!.isFileURL && audioFileTypes.contains(url!.pathExtension) {
                    self.playlist.append(url!)
                }
            }
            
            if self.playerHasMedia() == false {
                if updateIndexIfNew { self.trackIndex = 0 }
                if shouldPlay { self.play() }
            }
        }
    }
    
    func insertMedia(urls: [URL?], atIndex: Int, updateIndexIfNew: Bool, shouldPlay: Bool) {
        if urls.count > 0 {
            for i in 0...urls.count-1 {
                let url = urls[i]
                if url!.isFileURL && audioFileTypes.contains(url!.pathExtension) {
                    _ = url?.startAccessingSecurityScopedResource()
                    let n = atIndex+i
                    if self.playlist.count > n {
                        self.playlist.insert(url!, at: n)
                    } else {
                        self.addMedia(urls: [url], updateIndexIfNew: updateIndexIfNew, shouldPlay: shouldPlay)
                    }
                }
                
                if self.playerHasMedia() == false {
                    if updateIndexIfNew { self.trackIndex = 0 }
                    if shouldPlay { self.play() }
                }
            }
        }
    }
    
    func updatePlayer() {
        if self.player != nil {
            self.updateMetadata()
            self.lastIndex = self.trackIndex
            self.player.delegate = self
            self.notificationCenter.post(name: .mediaChanged, object: nil)
        }
    }
    
    func updateMetadata() {
        self.metadata = AudioMetadata(forURL: self.currentUrl)
        if self.metadata.artwork == nil {
            let pathComponents = self.currentUrl.pathComponents
            let directoryComponents = pathComponents.dropLast()
            var directoryPath = ""
            
            for component in directoryComponents {
                directoryPath += component+pathSep
            }
            
            let directoryURL = URL(fileURLWithPath: directoryPath)
            
            if directoryURL.hasDirectoryPath {
                let coverArtURL = getCoverArt(fromDirectory: directoryURL)
                if coverArtURL != nil {
                    var dataProvider: CGDataProvider!
                    do {
                        dataProvider = CGDataProvider(data: try Data(contentsOf: coverArtURL!) as CFData)
                    } catch let error {
                        print(error.localizedDescription)
                    }
                    
                    if dataProvider != nil {
                        let colorRendering = CGColorRenderingIntent(rawValue: 32)
                        
                        if colorRendering != nil {
                            if coverArtURL?.pathExtension == "jpg" || coverArtURL?.pathExtension == "jpeg" {
                                self.metadata.artwork = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: colorRendering!)
                            } else if coverArtURL?.pathExtension == "png" {
                                self.metadata.artwork = CGImage(pngDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: colorRendering!)
                            }
                        }
                    }
                }
            }
        }
    }

    func play() {
        if self.player != nil && playlistHasMedia() {
            self.player.play()
            self.state = .playing
        }
    }
    
    func pause() {
        if playerHasMedia() {
            self.player.pause()
        }
        
        if self.state == .playing {
            self.state = .paused
        }
    }
    
    func playPause() {
        if isPlaying() {
            self.pause()
        } else {
            self.play()
        }
    }
    
    func stop() {
        if self.player != nil {
            self.player.stop()
            self.state = .idle
        }
    }
    
    func toggleMute() {
        if self.muted {
            self.volume = lastVolume
            self.muted = false
        } else {
            self.lastVolume = volume
            self.volume = 0
            self.muted = true
        }
    }
    
    func nextTrack() {
        if self.playlistHasMedia() && self.playlist.count - 1 >= self.trackIndex + 1 {
            let wasPlaying = isPlaying()
            self.trackIndex += 1
            
            if wasPlaying {
                self.play()
            }
        }
    }
    
    func previousTrack() {
        if self.playlistHasMedia() && self.trackIndex > 0 {
            let wasPlaying = isPlaying()
            self.trackIndex -= 1
            
            if wasPlaying {
                self.play()
            }
        }
    }
    
    func isPlaying() -> Bool {
        if self.player != nil && self.player.isPlaying {
            return true
        } else {
            return false
        }
    }
    
    func playlistHasMedia(fromCurrentIndex: Bool = true) -> Bool {
        if fromCurrentIndex {
            return self.playlist.count - self.trackIndex > 0
        } else {
            return self.playlist.count > 0
        }
    }
    
    func playerHasMedia() -> Bool {
        if self.player == nil || self.player.currentDevice == nil {
            return false
        } else {
            return true
        }
    }
    
    func duration() -> Double {
        if self.player != nil {
            return self.player.duration
        } else {
            return 0.0
        }
    }
    
    func setPosition(position: Double) {
        if self.player != nil && position < duration() {
            self.player.currentTime = position
        }
    }
    
    func finishPlayback() {
        self.stop()
        self.updatePlayer()
        self.setPosition(position: 0.0)
    }
    
    func clear() {
        if self.player != nil && self.playlistHasMedia() {
            self.stop()
            self.currentUrl = nil
            self.playlist = []
            self.trackIndex = 0
            self.currentUrl = nil
            self.metadata = nil
        }
        
        self.clearPlaylistDefaults()
    }
    
    func removeMedia(atIndex index: Int) {
        if index >= 0 && index < self.playlist.count {
            self.playlist.remove(at: index)
            self.playlistChanged()
        }
    }
    
    func removeMedia(atIndexes indexes: [Int]) {
        if indexes.count > 0 {
            var modifiableIndexes = indexes
            for i in 0...modifiableIndexes.count-1 {
                self.removeMedia(atIndex: modifiableIndexes[i])
                for n in i...modifiableIndexes.count-1 {
                    modifiableIndexes[n] -= 1
                }
            }
        }
    }
    
    func mediaChanged() {
        self.notificationCenter.post(name: .mediaChanged, object: nil)
    }
    
    func playlistChanged() {
        self.notificationCenter.post(name: .playlistChanged, object: nil)
    }
    
    func seekTrack(index: Int) {
        if index >= 0 && index < self.playlist.count {
            let wasPlaying = isPlaying()
            
            self.currentUrl = playlist[index]
            self.updatePlayer()
            
            self.play()
            if !wasPlaying {
                self.pause()
            }
        }
    }
    
    func movePlaylistItems(fromIndex: Int, toIndex: Int, count: Int) {
        if count == 1 {
            let item = self.playlist[fromIndex]
            self.playlist.remove(at: fromIndex)
            self.playlist.insert(item, at: toIndex)
        } else {
            var items: [URL] = []
            let range = fromIndex...fromIndex+count-1
            for i in range {
                items.append(self.playlist[i])
            }
            
            self.playlist.removeSubrange(range)
            
            if toIndex > self.playlist.count-1 {
                self.playlist += items
            } else {
                self.playlist.insert(contentsOf: items, at: toIndex)
            }
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.trackIndex += 1
        self.lastIndex = self.trackIndex
        if self.playlistHasMedia() {
            self.play()
        } else {
            self.trackIndex -= 1
            self.finishPlayback()
        }
    }
    
    private func stateChanged() {
        switch self.state {
        case .idle:
            self.notificationCenter.post(name: .playbackStopped, object: nil)
        case .playing:
            self.notificationCenter.post(name: .playbackStarted, object: nil)
        case .paused:
            self.notificationCenter.post(name: .playbackPaused, object: nil)
        }
    }
}
