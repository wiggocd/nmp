//
//  AudioPlayer.swift
//  nmp
//
//  Created by C. Wiggins on 14/11/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import AVFoundation

class AudioPlayer: NSObject, AVAudioPlayerDelegate {
    private let application = Application.shared as? Application
    
    private var notificationCenter: NotificationCenter = .default
    private var positionTimer: Timer?
    private var indexUpdate = false
    private var positionUpdate = false
    private var lastQueuePlaylistCount = 0
    private var observations: [NSKeyValueObservation] = []
    private var lastPosition: TimeInterval = 0
    private var lastDuration: TimeInterval = 0
    private var lastPlaylist: [URL] = []
    private var lastQueueCount = 0
    
    var audioPlayer = AVQueuePlayer()
    
    private var playlist: [URL] = [] {
        didSet {
            self.playlistChanged()
            
            var strings: [String] = []
            for item in playlist {
                strings.append(item.absoluteString)
            }
            
            self.application?.userDefaults.set(strings, forKey: "Playlist")
            self.lastPlaylist = playlist
        }
    }
    
    var playlistIndex: Int? {
        didSet {
            if !self.indexUpdate {
                guard let newValue = self.playlistIndex else { return }
                
                if newValue >= 0 && newValue < self.playlist.count {
                    self.audioPlayer.removeAllItems()
                    self.audioPlayer.insert(AVPlayerItem(url: self.playlist[newValue]), after: nil)
                    self.updatePlayerQueue(fromPlaylist: self.playlist, withStartingIndex: newValue + 1)
                }
                
                self.itemDidStartPlaying(userSelected: true)
            }
            
            self.application?.userDefaults.set(playlistIndex, forKey: "PlaylistIndex")
        }
    }
    
    var currentURL: URL? {
        if let playlistIndex = self.playlistIndex, self.audioObjectHasMedia()
            && playlistIndex >= 0
            && playlistIndex < self.playlist.count {
            return self.playlist[playlistIndex]
        }
        
        return nil
    }
    
    var duration: TimeInterval {
        if let item = self.audioPlayer.currentItem, item.asset.duration.isNumeric {
            return CMTimeGetSeconds(item.asset.duration)
        }
        
        return 0
    }
    
    var position: TimeInterval = 0 {
        didSet {
            if self.lastPosition + 1 >= self.lastDuration {
                self.mediaChanged()
            }
            
            if !self.positionUpdate {
                let newTime = CMTime(seconds: position, preferredTimescale: .max)
                self.audioPlayer.seek(to: newTime)
                self.positionSet()
            }
            
            self.lastPosition = position
            self.lastDuration = self.duration
        }
    }
    
    var volume: Float {
        get {
            return self.audioPlayer.volume
        } set {
            self.audioPlayer.volume = newValue
        }
    }
    
    var rate: Float {
        return self.audioPlayer.rate
    }
    
    var state: PlayerState = .idle {
        didSet {
            self.stateChanged()
        }
    }
    
    var metadata: AudioMetadata?
    
    override init() {
        super.init()
        
        self.addObservers()
        
        if self.loadPlaylistFromDefaults() {
            self.loadTrackIndexFromDefaults()
        }
    }
    
    convenience init(notificationCenter: NotificationCenter = .default) {
        self.init()
        self.notificationCenter = notificationCenter
    }
    
    deinit {
        self.removeObservers()
    }
    
    func addObservers() {
        self.notificationCenter.addObserver(self, selector: #selector(self.itemDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        self.observations = [
            self.audioPlayer.observe(\.rate, changeHandler: { _,_ in
                self.rateChanged()
            })
        ]
    }
    
    func removeObservers() {
        for observation in self.observations {
            observation.invalidate()
        }
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
            let playerHadMedia = self.audioObjectHasMedia()
            
            var mediaURLs = urls
            var sorted = false
            var i = 0
            while !sorted {
                if !mediaURLs[i]!.isFileURL || !audioFileTypes.contains(mediaURLs[i]!.pathExtension) {
                    mediaURLs.remove(at: i)
                } else {
                    i+=1
                }
                
                if i >= mediaURLs.count {
                    sorted = true
                }
            }
            
            self.playlist.append(contentsOf: mediaURLs as! [URL])
            
            updatePlayerQueue(fromPlaylist: self.playlist, withStartingIndex: self.playlistIndex ?? 0)
            if updateIndexIfNew && !playerHadMedia { self.playlistIndex = 0 }
            if !shouldPlay && !self.audioObjectHasMedia() { self.pause() }
            
            self.startPositionTimer()
        }
    }
    
    private func updatePlayerQueue(fromPlaylist playlist: [URL], withStartingIndex startingIndex: Int = 0) {
        if playlist.count > 0 {
            let currentItemRemoved: Bool
            if let playlistIndex = self.playlistIndex,
               playlistIndex < playlist.count && playlistIndex < self.lastPlaylist.count
                && playlist[playlistIndex] != self.lastPlaylist[playlistIndex] {
                currentItemRemoved = true
            } else {
                currentItemRemoved = false
            }
            
            let initalQueueCount = self.audioPlayer.items().count
            let itemsRemoved = playlist.count < self.lastQueuePlaylistCount
            let newQueueItems = playlist.count - startingIndex > self.lastQueueCount
            let queueStartingIndex = !currentItemRemoved && (newQueueItems || itemsRemoved) ?
                startingIndex + 1 : startingIndex
             if queueStartingIndex < playlist.count {
                for i in queueStartingIndex..<playlist.count {
                    self.audioPlayer.insert(AVPlayerItem(url: playlist[i]), after: nil)
                }
            }
            
            
            var i = 1
            while i < initalQueueCount {
                self.audioPlayer.remove(self.audioPlayer.items()[1])
                i+=1
            }
            
            if currentItemRemoved {
                self.audioPlayer.replaceCurrentItem(with: nil)
            }
        } else {
            self.audioPlayer.removeAllItems()
        }
        
        self.lastQueueCount = self.audioPlayer.items().count
        self.lastQueuePlaylistCount = playlist.count
        self.mediaChanged()
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
            var mediaURLs = urls
            var sorted = false
            var i = 0
            while !sorted {
                if !mediaURLs[i].isFileURL || !audioFileTypes.contains(mediaURLs[i].pathExtension) {
                    mediaURLs.remove(at: i)
                } else {
                    i+=1
                }
                
                if i >= mediaURLs.count {
                    sorted = true
                }
            }
            
            self.playlist.insert(contentsOf: mediaURLs, at: index)
            
            if self.audioObjectHasMedia() {
                if updateIndexIfNew { self.playlistIndex = 0 }
                if !shouldPlay { self.pause() }
            }
            
            self.startPositionTimer()
            updatePlayerQueue(fromPlaylist: playlist, withStartingIndex: self.playlistIndex ?? 0)
        }
    }
    
    func removeMedia(atIndex index: Int) {
        if index >= 0 && index < self.playlist.count {
            self.playlist.remove(at: index)
            updatePlayerQueue(fromPlaylist: playlist, withStartingIndex: self.playlistIndex ?? 0)
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
        
        updatePlayerQueue(fromPlaylist: playlist, withStartingIndex: self.playlistIndex ?? 0)
    }
    
    func play() {
        self.audioPlayer.play()
        self.updateState()
    }
    
    func pause() {
        self.audioPlayer.pause()
        self.updateState()
    }
    
    func playPause() {
        if self.isPlaying() {
            self.pause()
        } else {
            self.play()
        }
    }
    
    func stop() {
        self.pause()
        self.audioPlayer.replaceCurrentItem(with: nil)
        self.state = .idle
        self.mediaChanged()
    }
    
    func mute() {
        self.audioPlayer.isMuted = true
    }
    
    func unmute() {
        self.audioPlayer.isMuted = false
    }
    
    func toggleMute() {
        self.audioPlayer.isMuted.toggle()
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
        self.playlistIndex = nil
        self.playlist = []
        self.updatePlayerQueue(fromPlaylist: self.playlist)
        self.stop()
    }
    
    func updateMetadata() {
        guard let currentURL = self.currentURL else {
            self.metadata = nil
            return
        }
        
        let newMetadata = AudioMetadata(forURL: currentURL)
        if self.metadata != newMetadata {
            self.metadata = newMetadata
            if let metadata = self.metadata, metadata.artwork == nil {
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
                                    metadata.artwork = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: colorRendering!)
                                } else if coverArtURL?.pathExtension == "png" {
                                    metadata.artwork = CGImage(pngDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: colorRendering!)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func items() -> [URL] {
        return self.playlist
    }
    
    func audioObjectHasMedia() -> Bool {
        return self.audioPlayer.currentItem != nil || self.audioPlayer.items().count > 0
    }
    
    func playlistHasMedia() -> Bool {
        return self.playlist.count > 0
    }
    
    func hasMedia() -> Bool {
        return self.audioObjectHasMedia() || self.playlistHasMedia()
    }
    
    func isPlaying() -> Bool {
        return self.state == .playing
    }
    
    private func startPositionTimer() {
        self.positionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in
            self.updatePosition()
        })
    }
    
    private func killPositionTimer() {
        self.positionTimer?.invalidate()
        self.positionTimer = nil
    }
    
    private func itemDidStartPlaying(userSelected: Bool) {
        if let playlistIndex = self.playlistIndex, !userSelected {
            self.sendPlaylistUpdate(newValue: playlistIndex + 1)
        }
        
        self.updatePosition()
        self.mediaChanged()
    }
    
    @objc private func itemDidFinishPlaying() {
        if self.playlistIndex != self.playlist.count - 1 {
            self.updateState()

            DispatchQueue.main.async {
                self.itemDidStartPlaying(userSelected: false)
            }
        } else {
            self.audioPlayer.removeAllItems()
            self.stop()
            self.playlistIndex = nil
            self.metadata = nil
            self.updatePosition()
        }
    }
    
    private func updateState() {
        if self.audioObjectHasMedia() {
            if self.audioPlayer.rate > 0 {
                self.state = .playing
            } else {
                self.state = .paused
            }
        } else {
            self.state = .idle
        }
    }
    
    private func updatePosition() {
        self.positionUpdate = true
        self.position = CMTimeGetSeconds(self.audioPlayer.currentTime())
        self.positionUpdate = false
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
            self.killPositionTimer()
        case .playing:
            self.notificationCenter.post(name: .playbackStarted, object: nil)
            self.startPositionTimer()
        case .paused:
            self.notificationCenter.post(name: .playbackPaused, object: nil)
            self.killPositionTimer()
        }
    }
    
    private func mediaChanged() {
        self.updateMetadata()
        self.notificationCenter.post(name: .mediaChanged, object: nil)
    }
    
    private func playlistChanged() {
        self.notificationCenter.post(name: .playlistChanged, object: nil)
    }
    
    private func rateChanged() {
        self.notificationCenter.post(name: .rateChanged, object: nil)
    }
    
    private func positionSet() {
        self.notificationCenter.post(name: .positionSet, object: nil)
    }
}
