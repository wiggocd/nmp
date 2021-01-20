//
//  AudioPlayer.swift
//  nmp
//
//  Created by C. Wiggins on 14/11/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import StreamingKit
import AVFoundation

class AudioPlayer: NSObject, STKAudioPlayerDelegate {
    private let application = Application.shared as? Application
    private var audioPlayer: STKAudioPlayer? = STKAudioPlayer()
    
    private var notificationCenter: NotificationCenter = .default
    private var indexUpdate = false
    private var shouldPlayAfterLoad = false
    private var nextItem: URL?
    private var currentAsset: AVURLAsset?
    private var lastPlaylistCount = 0
    
    var playlist: [URL] = [] {
        didSet {
            let removalStartingIndex = self.playlistIndex == nil ? 0
                : self.playlistIndex!
            if playlist.count < self.lastPlaylistCount { updatePlayerQueue(fromPlaylist: playlist, withStartingIndex: removalStartingIndex) }
            self.playlistChanged()
            
            var strings: [String] = []
            for item in playlist {
                strings.append(item.absoluteString)
            }
            
            self.application?.userDefaults.set(strings, forKey: "Playlist")
            self.lastPlaylistCount = playlist.count
        }
    }
    
    var playlistIndex: Int? {
        didSet {
            if !self.indexUpdate {
                guard let newValue = playlistIndex else { return }
                
                if newValue >= 0 && newValue < self.playlist.count {
                    let wasPlaying = self.isPlaying()
                    self.audioPlayer?.play(self.playlist[newValue])
                    if !wasPlaying { self.pause() }
                    
                    updatePlayerQueue(fromPlaylist: playlist, withStartingIndex: newValue)
                }
            }
            
            self.application?.userDefaults.set(playlistIndex, forKey: "PlaylistIndex")
        }
    }
    
    var currentURL: URL? {
        if self.playerHasMedia() {
            return self.audioPlayer?.currentlyPlayingQueueItemId() as? URL
        }
        return nil
    }
    
    var duration: TimeInterval {
        if let asset = self.currentAsset {
            let audioDuration = asset.duration
            return CMTimeGetSeconds(audioDuration)
        }
        
        return 0
    }
    
    var position: TimeInterval {
        get {
            if let player = self.audioPlayer {
                return player.progress
            } else {
                return 0
            }
        } set {
            if newValue < self.duration {
                self.audioPlayer?.seek(toTime: newValue)
            }
        }
    }
    
    var volume: Float {
        get {
            if let player = self.audioPlayer {
                return player.volume
            } else {
                return 0
            }
        } set {
            self.audioPlayer?.volume = newValue
        }
    }
    
    var rate: Float {
        return 0
    }
    
    var state: PlayerState = .idle {
        didSet {
            self.stateChanged()
        }
    }
    
    var metadata: AudioMetadata?
    
    override init() {
        super.init()
        self.audioPlayer?.delegate = self
        
        if self.loadPlaylistFromDefaults() {
            self.loadTrackIndexFromDefaults()
        }
    }
    
    convenience init(notificationCenter: NotificationCenter = .default) {
        self.init()
        self.notificationCenter = notificationCenter
    }
    
    func loadPlaylistFromDefaults() -> Bool {
        loadBookmarkData()
        let playlistData = self.application?.userDefaults.array(forKey: "Playlist") as? [String]
        var urls: [URL] = []
        
        if playlistData != nil && playlistData != [] {
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
            self.addMedia(urls: urls, updateIndexIfNew: false, shouldPlay: false, async: false)
            return true
        } else {
            return false
        }
    }
    
    func loadTrackIndexFromDefaults() {
        if let data = self.application?.userDefaults.integer(forKey: "PlaylistIndex") {
            self.playlistIndex = data
        }
    }
    
    func clearPlaylistDefaults() {
        self.application?.userDefaults.removeObject(forKey: "TrackIndex")
        self.application?.userDefaults.removeObject(forKey: "Playlist")
    }
    
    func addMedia(urls: [URL?], updateIndexIfNew: Bool, shouldPlay: Bool, async: Bool = true) {
        if async {
            DispatchQueue.main.async {
                self._addMedia(urls: urls, updateIndexIfNew: updateIndexIfNew, shouldPlay: shouldPlay)
            }
        } else {
            self._addMedia(urls: urls, updateIndexIfNew: updateIndexIfNew, shouldPlay: shouldPlay)
        }
    }
    
    private func _addMedia(urls: [URL?], updateIndexIfNew: Bool, shouldPlay: Bool) {
        if urls.count > 0 {
            for url in urls {
                if url!.isFileURL && audioFileTypes.contains(url!.pathExtension) {
                    self.playlist.append(url!)
                }
            }
            
            if updateIndexIfNew && !self.playerHasMedia() { self.playlistIndex = 0 }
            self.shouldPlayAfterLoad = shouldPlay
        }
    }
    
    private func updatePlayerQueue(fromPlaylist playlist: [URL], withStartingIndex startingIndex: Int = 0) {
        let currentId = self.audioPlayer?.currentlyPlayingQueueItemId()
        
        self.audioPlayer?.clearQueue()
        
        if playlist.count > 0 {
            let upperBound = self.isPlaying() && currentId as? URL == self.playlist[self.playlist.count - 2] ?
            playlist.count - 1 : playlist.count
            
            for i in startingIndex..<upperBound {
                self.audioPlayer?.queue(playlist[i])
            }
        }
        
    }
    
    func insertMedia(urls: [URL], atIndex index: Int, updateIndexIfNew: Bool, shouldPlay: Bool, async: Bool = true) {
        if async {
            DispatchQueue.main.async {
                self._insertMedia(urls: urls, atIndex: index, updateIndexIfNew: updateIndexIfNew, shouldPlay: shouldPlay)
            }
        } else {
            self._insertMedia(urls: urls, atIndex: index, updateIndexIfNew: updateIndexIfNew, shouldPlay: shouldPlay)
        }
    }
    
    private func _insertMedia(urls: [URL], atIndex index: Int, updateIndexIfNew: Bool, shouldPlay: Bool) {
        if urls.count > 0 {
            for i in 0..<urls.count {
                self.playlist.insert(urls[i], at: index + i)
            }
            
            if updateIndexIfNew && !self.playerHasMedia() { self.playlistIndex = 0 }
            self.shouldPlayAfterLoad = shouldPlay
        }
    }
    
    func removeMedia(atIndex index: Int) {
        if index >= 0 && index < self.playlist.count {
            self.playlist.remove(at: index)
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
    
    func play() {
        self.audioPlayer?.resume()
        self.shouldPlayAfterLoad = true
    }
    
    func pause() {
        self.audioPlayer?.pause()
    }
    
    func playPause() {
        if self.isPlaying() {
            self.pause()
        } else {
            self.play()
        }
    }
    
    func stop() {
        self.audioPlayer?.pause()
        self.audioPlayer?.stop()
    }
    
    func mute() {
        self.audioPlayer?.mute()
    }
    
    func unmute() {
        self.audioPlayer?.unmute()
    }
    
    func toggleMute() {
        if let player = self.audioPlayer {
            if player.muted {
                player.unmute()
            } else {
                player.mute()
            }
        }
    }
    
    func nextTrack() {
        if let playlistIndex = self.playlistIndex {
            let newIndex = playlistIndex + 1
            if newIndex >= 0 && newIndex < self.playlist.count {
                self.playlistIndex = newIndex
            }
        }
    }
    
    func previousTrack() {
        if let playlistIndex = self.playlistIndex {
            let newIndex = playlistIndex - 1
            if newIndex >= 0 && newIndex < self.playlist.count {
                self.playlistIndex = newIndex
            }
        }
    }
    
    func clear() {
        self.playlistIndex = 0
        self.playlist = []
        self.audioPlayer?.stop()
    }
    
    func destroy() {
        self.audioPlayer?.delegate = nil
        self.audioPlayer = nil
    }
    
    func updateMetadata() {
        guard let currentURL = self.currentURL else { return }
        let newMetadata = AudioMetadata(forURL: currentURL)
        if self.metadata != newMetadata {
            self.metadata = newMetadata
            if self.metadata != nil && self.metadata!.artwork == nil {
                let pathComponents = currentURL.pathComponents
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
                                    self.metadata!.artwork = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: colorRendering!)
                                } else if coverArtURL?.pathExtension == "png" {
                                    self.metadata!.artwork = CGImage(pngDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: colorRendering!)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func playerHasMedia() -> Bool {
        if let player = self.audioPlayer {
            return player.pendingQueueCount > 0
            || player.state == .playing
            || player.state == .running
            || player.state == .paused
            || player.state == .buffering
        }
        
        return false
    }
    
    func playlistHasMedia() -> Bool {
        return self.playlist.count > 0
    }
    
    func isPlaying() -> Bool {
        return self.state == .playing
    }
    
    func isNextItem() -> Bool {
        return nextItem == currentURL
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didStartPlayingQueueItemId queueItemId: NSObject) {
        if let playlistIndex = self.playlistIndex {
            if isNextItem() {
                self.sendPlaylistUpdate(newValue: playlistIndex + 1)
            }
            
            if self.audioPlayer?.pendingQueueCount == 0 {
                self.updatePlayerQueue(fromPlaylist: self.playlist, withStartingIndex: playlistIndex + 1)
            }
        }
        
        if self.shouldPlayAfterLoad {
            self.play()
        } else {
            self.pause()
            self.shouldPlayAfterLoad = true
        }
        
        DispatchQueue.main.async {
            self.mediaChanged()
        }
        
        self.position = 0
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didFinishBufferingSourceWithQueueItemId queueItemId: NSObject) {
        
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, stateChanged state: STKAudioPlayerState, previousState: STKAudioPlayerState) {
        switch state {
        case .playing:
            self.state = .playing
        case .paused:
            self.state = .paused
        default:
            self.state = .idle
        }
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didFinishPlayingQueueItemId queueItemId: NSObject, with stopReason: STKAudioPlayerStopReason, andProgress progress: Double, andDuration duration: Double) {
        if let playlistIndex = self.playlistIndex, playlistIndex < self.playlist.count {
            if playlistIndex + 1 < self.playlist.count {
                self.nextItem = self.playlist[playlistIndex + 1]
            }
        }
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, unexpectedError errorCode: STKAudioPlayerErrorCode) {
        print("STKAudioPlayer error: \(errorCode)")
    }
    
    private func sendPlaylistUpdate(newValue: Int) {
        self.indexUpdate = true
        self.playlistIndex = newValue
        self.indexUpdate = false
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
    
    private func mediaChanged() {
        if let url = self.currentURL {
            self.currentAsset = AVURLAsset(url: url)
        }
        self.updateMetadata()
        self.notificationCenter.post(name: .mediaChanged, object: nil)
    }
    
    private func playlistChanged() {
        self.notificationCenter.post(name: .playlistChanged, object: nil)
    }
}