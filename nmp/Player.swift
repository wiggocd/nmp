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
            notificationCenter.post(name: .playlistChanged, object: nil)
            var strings: [String] = []
            for item in playlist {
                if let bookmarkData = UserDefaults.standard.object(forKey: urlBookmarkKey) as? Data {
                    do {
                        var dataIsStale = false
                        _ = try URL(resolvingBookmarkData: bookmarkData, options: .withoutUI, relativeTo: nil, bookmarkDataIsStale: &dataIsStale)
                        strings.append(item.absoluteString)
                    } catch {
                        return
                    }
                }
            }
            application?.userDefaults.set(strings, forKey: "Playlist")
        }
    }
    
    var trackIndex: Int! {
        didSet {
            seekTrack(index: trackIndex)
            application?.userDefaults.set(trackIndex, forKey: "TrackIndex")
        }
    }
    
    var metadata: AudioMetadata!
    var lastIndex = 0
    var currentUrl: URL! {
        didSet {
            if currentUrl == nil {
                player = nil
            } else {
                do {
                    player = try AVAudioPlayer(contentsOf: currentUrl)
                    player.volume = volume
                    mediaChanged()
                } catch let error {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    var position: TimeInterval {
        get {
            if player != nil {
                return player.currentTime
            } else {
                return 0.0
            }
        }
    }
    
    var volume: Float = 1.0 {
        didSet {
            if player != nil {
                player.volume = volume
            }
        }
    }
    
    private var lastVolume: Float = 1.0
    var muted = false
    
    @Published var state = PlayerState.idle {
        didSet { stateChanged() }
    }
    
    init(notificationCenter: NotificationCenter = .default) {
        super.init()
        self.notificationCenter = notificationCenter
        
        if loadPlaylistFromDefaults() {
            loadTrackIndexFromDefaults()
        }
        
        if trackIndex == nil {
            trackIndex = 0
        }
    }
    
    func loadPlaylistFromDefaults() -> Bool {
        let playlistData = application?.userDefaults.array(forKey: "Playlist") as? [String]
        var urls: [URL] = []
        
        if playlistData != nil {
            if playlistData!.count > 0 {
                for item in playlistData! {
                    if let url = URL(string: item) {
                        urls.append(url)
                    }
                }
            }
        }
        
        if urls.count > 0 {
            addMedia(urls: urls, updateIndexIfNew: false, shouldPlay: false)
            return true
        } else {
            return false
        }
    }
    
    func loadTrackIndexFromDefaults() {
        if let data = application?.userDefaults.integer(forKey: "TrackIndex") {
            trackIndex = data
        }
    }
    
    func clearPlaylistDefaults() {
        application?.userDefaults.removeObject(forKey: "TrackIndex")
        application?.userDefaults.removeObject(forKey: "Playlist")
    }
    
    func addMedia(urls: [URL?], updateIndexIfNew: Bool, shouldPlay: Bool) {
        if urls.count > 0 {
            for url in urls {
                if url!.isFileURL && audioFileTypes.contains(url!.pathExtension) {
                    playlist.append(url!)
                }
            }
            
            if playerHasMedia() == false {
                if updateIndexIfNew { trackIndex = 0 }
                if shouldPlay { play() }
            }
        }
    }
    
    func insertMedia(urls: [URL?], atIndex: Int, updateIndexIfNew: Bool, shouldPlay: Bool) {
        if urls.count > 0 {
            for i in 0...urls.count-1 {
                let url = urls[i]
                if url!.isFileURL && audioFileTypes.contains(url!.pathExtension) {
                    let n = atIndex+i
                    if playlist.count > n {
                        playlist.insert(url!, at: n)
                    } else {
                        addMedia(urls: [url], updateIndexIfNew: updateIndexIfNew, shouldPlay: shouldPlay)
                    }
                }
                
                if playerHasMedia() == false {
                    if updateIndexIfNew { trackIndex = 0 }
                    if shouldPlay { play() }
                }
            }
        }
    }
    
    func updatePlayer() {
        if player != nil {
            updateMetadata()
            lastIndex = trackIndex
            player.delegate = self
            notificationCenter.post(name: .mediaChanged, object: nil)
        }
    }
    
    func updateMetadata() {
        metadata = AudioMetadata(playerItem: AVPlayerItem(url: currentUrl))
        if metadata.artwork == nil {
            let pathComponents = currentUrl.pathComponents
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

    func play() {
        if player != nil && playlistHasMedia() {
            player.play()
            state = .playing
        }
    }
    
    func pause() {
        if playerHasMedia() {
            switch state {
            case .idle, .paused:
                break
            case .playing:
                player.pause()
            }
        }
        
        if state == .playing {
            state = .paused
        }
    }
    
    func playPause() {
        if isPlaying() {
            pause()
        } else {
            play()
        }
    }
    
    func stop() {
        if player != nil {
            player.stop()
            state = .idle
        }
    }
    
    func toggleMute() {
        if muted {
            volume = lastVolume
            muted = false
        } else {
            lastVolume = volume
            volume = 0
            muted = true
        }
    }
    
    func nextTrack() {
        if playlistHasMedia() && playlist.count - 1 >= trackIndex + 1 {
            let wasPlaying = isPlaying()
            trackIndex += 1
            
            if wasPlaying {
                play()
            }
        }
    }
    
    func previousTrack() {
        if playlistHasMedia() && trackIndex > 0 {
            let wasPlaying = isPlaying()
            trackIndex -= 1
            
            if wasPlaying {
                play()
            }
        }
    }
    
    func isPlaying() -> Bool {
        if player != nil && player.isPlaying {
            return true
        } else {
            return false
        }
    }
    
    func playlistHasMedia(fromCurrentIndex: Bool = true) -> Bool {
        if fromCurrentIndex {
            return playlist.count - trackIndex > 0
        } else {
            return playlist.count > 0
        }
    }
    
    func playerHasMedia() -> Bool {
        if player == nil || player.currentDevice == nil {
            return false
        } else {
            return true
        }
    }
    
    func duration() -> Double {
        if player != nil {
            return player.duration
        } else {
            return 0.0
        }
    }
    
    func setPosition(position: Double) {
        if player != nil && position < duration() {
            player.currentTime = position
        }
    }
    
    func finishPlayback() {
        stop()
        updatePlayer()
        setPosition(position: 0.0)
    }
    
    func clear() {
        if player != nil && playlistHasMedia() {
            stop()
            currentUrl = nil
            playlist = []
            trackIndex = 0
            currentUrl = nil
            metadata = nil
        }
        
        clearPlaylistDefaults()
    }
    
    func removeMedia(atIndex index: Int) {
        if index >= 0 && index < playlist.count {
            playlist.remove(at: index)
            playlistChanged()
        }
    }
    
    func removeMedia(atIndexes indexes: [Int]) {
        if indexes.count > 0 {
            var modifiableIndexes = indexes
            for i in 0...modifiableIndexes.count-1 {
                removeMedia(atIndex: modifiableIndexes[i])
                for n in i...modifiableIndexes.count-1 {
                    modifiableIndexes[n] -= 1
                }
            }
        }
    }
    
    func mediaChanged() {
        notificationCenter.post(name: .mediaChanged, object: nil)
    }
    
    func playlistChanged() {
        notificationCenter.post(name: .playlistChanged, object: nil)
    }
    
    func seekTrack(index: Int) {
        if index >= 0 && index < playlist.count {
            let wasPlaying = isPlaying()
            
            currentUrl = playlist[index]
            updatePlayer()
            
            play()
            if !wasPlaying {
                pause()
            }
        }
    }
    
    func movePlaylistItems(fromIndex: Int, toIndex: Int, count: Int) {
        if count == 1 {
            let item = playlist[fromIndex]
            playlist.remove(at: fromIndex)
            playlist.insert(item, at: toIndex)
        } else {
            var items: [URL] = []
            let range = fromIndex...fromIndex+count-1
            for i in range {
                items.append(playlist[i])
            }
            
            playlist.removeSubrange(range)
            
            if toIndex > playlist.count-1 {
                playlist += items
            } else {
                playlist.insert(contentsOf: items, at: toIndex)
            }
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        trackIndex += 1
        lastIndex = trackIndex
        if playlistHasMedia() {
            play()
        } else {
            trackIndex -= 1
            finishPlayback()
        }
    }
    
    private func stateChanged() {
        switch state {
        case .idle:
            notificationCenter.post(name: .playbackStopped, object: nil)
        case .playing:
            notificationCenter.post(name: .playbackStarted, object: nil)
        case .paused:
            notificationCenter.post(name: .playbackPaused, object: nil)
        }
    }
}
