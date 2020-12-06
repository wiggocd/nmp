//
//  Player.swift
//  nmp
//
//  Created by Kate Wiggins on 14/11/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import AVFoundation

class AudioPlayer: NSObject, AVAudioPlayerDelegate {
    var player: AVAudioPlayer!
    private var notificationCenter: NotificationCenter!
    var playlist: [URL] = [] {
        didSet {
            notificationCenter.post(name: .playlistChanged, object: nil)
        }
    }
    var playlistIndex = 0 {
        didSet {
            seekTrack(index: playlistIndex)
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
                    mediaChanged()
                } catch let error {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    @Published var state = PlayerState.idle {
        didSet { stateChanged() }
    }
    
    init(notificationCenter: NotificationCenter = .default) {
        super.init()
        self.notificationCenter = notificationCenter
    }
    
    func addMedia(urls: [URL?]) {
        for url in urls {
            if url!.isFileURL && allowedFileTypes.contains(url!.pathExtension) {
                playlist.append(url!)
            }
        }
        
        if playerHasMedia() == false {
            playlistIndex = 0
            play()
        }
    }
    
    func updatePlayer() {
        updateMetadata()
        lastIndex = playlistIndex
        player.delegate = self
        notificationCenter.post(name: .mediaChanged, object: nil)
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
        if playlistHasMedia() {
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
    
    func playpause() {
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
    
    func nextTrack() {
        if playlistHasMedia() && playlist.count - 1 >= playlistIndex + 1 {
            let wasPlaying = isPlaying()
            playlistIndex += 1
            
            if wasPlaying {
                play()
            }
        }
    }
    
    func previousTrack() {
        if playlistHasMedia() && playlistIndex > 0 {
            let wasPlaying = isPlaying()
            playlistIndex -= 1
            
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
            return playlist.count - playlistIndex > 0
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
    
    func position() -> TimeInterval {
        if player != nil {
            return player.currentTime
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
            playlistIndex = 0
            currentUrl = nil
            metadata = nil
        }
    }
    
    func removeMedia(atIndex index: Int) {
        if index >= 0 || index < playlist.count {
            if index == playlistIndex {
                if index > playlist.count - 2 {
                    playlist.remove(at: index)
                    currentUrl = nil
                    playlistIndex = index
                } else {
                    playlist.remove(at: index)
                    playlistIndex = index
                    
                    let wasPlaying = isPlaying()
                    currentUrl = playlist[playlistIndex]
                    play()
                    if !wasPlaying {
                        pause()
                    }
                }
            } else {
                playlist.remove(at: index)
            }
        }
    }
    
    func mediaChanged() {
        notificationCenter.post(name: .mediaChanged, object: nil)
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
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playlistIndex += 1
        lastIndex = playlistIndex
        if playlistHasMedia() {
            play()
        } else {
            playlistIndex -= 1
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

enum PlayerState {
    case idle
    case playing
    case paused
}

extension Notification.Name {
    static var playlistChanged: Notification.Name {
        return .init("AudioPlayer.playlistChanged")
    }
    
    static var mediaChanged: Notification.Name {
        return .init("AudioPlayer.mediaChanged")
    }
    
    static var playbackStarted: Notification.Name {
        return .init("AudioPlayer.playbackStarted")
    }
    
    static var playbackPaused: Notification.Name {
        return .init("AudioPlayer.playbackPaused")
    }
    
    static var playbackStopped: Notification.Name {
        return .init("AudioPlayer.playbackStopped")
    }
    
    static var trackPositionChanged: Notification.Name {
        return .init("AudioPlayer.trackPositionChanged")
    }
}
