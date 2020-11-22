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
    var playlist: [URL] = []
    var playlistIndex = 0
    var metadata: AudioMetadata!
    var lastIndex = 0
    var currentUrl: URL!
    
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
                self.playlist.append(url!)
            }
        }
        
        if self.playerHasMedia() == false {
            self.play()
        }
        
        self.mediaChanged()
    }
    
    func updatePlayer() {
        self.currentUrl = self.playlist[self.playlistIndex]
        self.metadata = AudioMetadata(playerItem: AVPlayerItem(url: self.currentUrl))
        self.lastIndex = self.playlistIndex
        
        do {
            self.player = try AVAudioPlayer(contentsOf: self.currentUrl)
            self.player.delegate = self
        } catch let error {
            print(error.localizedDescription)
        }
        
        self.notificationCenter.post(name: .mediaChanged, object: nil)
    }

    func play() {
        if self.playlistHasMedia() {
            if self.player == nil || self.playerHasMedia() == false || self.playlistIndex != self.lastIndex {
                self.updatePlayer()
            }
            
            self.player.play()
            self.state = .playing
        }
    }
    
    func pause() {
        if self.playerHasMedia() {
            switch self.state {
            case .idle, .paused:
                break
            case .playing:
                self.player.pause()
            }
        }
        
        if self.state == .playing {
            self.state = .paused
        }
    }
    
    func playpause() {
        if self.isPlaying() {
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
    
    func nextTrack() {
        if self.playlistHasMedia() && self.playlist.count - 1 >= self.playlistIndex + 1 {
            let wasPlaying = self.isPlaying()
            self.playlistIndex += 1
            self.updatePlayer()
            
            if wasPlaying {
                self.play()
            }
        }
    }
    
    func previousTrack() {
        if self.playlistHasMedia() && self.playlistIndex > 0 {
            let wasPlaying = self.isPlaying()
            self.playlistIndex -= 1
            self.updatePlayer()
            
            if wasPlaying {
                self.play()
            }
        }
    }
    
    func isPlaying() -> Bool {
        return self.player != nil && self.player.isPlaying
    }
    
    func playlistHasMedia(fromCurrentIndex: Bool = true) -> Bool {
        if fromCurrentIndex {
            if self.playlist.count - self.playlistIndex > 0 {
                return true
            } else {
                return false
            }
        } else {
            if self.playlist.count > 0 {
                return true
            } else {
                return false
            }
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
    
    func position() -> TimeInterval {
        if self.player != nil {
            return self.player.currentTime
        } else {
            return 0.0
        }
    }
    
    func setPosition(position: Double) {
        if self.player != nil && position < self.duration() {
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
            self.player = nil
            self.playlist = []
            self.playlistIndex = 0
            self.currentUrl = nil
            self.metadata = nil
            self.mediaChanged()
        }
    }
    
    func mediaChanged() {
        self.notificationCenter.post(name: .mediaChanged, object: nil)
    }
    
    private func stateChanged() {
        switch self.state {
        case .idle:
            self.notificationCenter.post(name: .playbackStopped, object: nil)
        case .playing:
            notificationCenter.post(name: .playbackStarted, object: nil)
        case .paused:
            notificationCenter.post(name: .playbackPaused, object: nil)
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.playlistIndex += 1
        if self.playlistHasMedia() {
            self.play()
        } else {
            self.playlistIndex -= 1
            self.finishPlayback()
        }
    }
}

enum PlayerState {
    case idle
    case playing
    case paused
}

extension Notification.Name {
    static var playbackStarted: Notification.Name {
        return .init("AudioPlayer.playbackStarted")
    }
    
    static var playbackPaused: Notification.Name {
        return .init("AudioPlayer.playbackPaused")
    }
    
    static var playbackStopped: Notification.Name {
        return .init("AudioPlayer.playbackStopped")
    }
    
    static var mediaChanged: Notification.Name {
        return .init("AudioPlayer.mediaChanged)")
    }
    
    static var trackPositionChanged: Notification.Name {
        return .init("AudioPlayer.trackPositionChanged")
    }
}
