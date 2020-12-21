//
//  ViewSelectors.swift
//  nmp
//
//  Created by C. Wiggins on 06/12/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import Cocoa
import MediaPlayer

extension PlayerViewController {
    @objc func refresh() {
        setBackgroundViewAndAppearance()
    }
    
    @objc func updatePosition() {
        self.timeSlider.doubleValue = self.player.position
        self.positionLabel.stringValue = to_hhmmss(seconds: self.player.position)
        if self.newPlaybackPositionTime != nil {
            self.nowPlayingInfoCenter.nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.player.position
            self.newPlaybackPositionTime = nil
        }
    }
    
    @objc func playlistChanged(_ notification: Notification) {
        updatePlaylist()
    }
    
    @objc func mediaChanged(_ notification: Notification) {
        updateMedia()
    }
    
    @objc func playbackStarted(_ notification: Notification) {
        self.playPauseButton.image = NSImage(named: "Pause")
        self.nowPlayingInfoCenter.playbackState = .playing
    }
    
    @objc func playbackPaused(_ notification: Notification) {
        self.playPauseButton.image = NSImage(named: "Play")
        self.nowPlayingInfoCenter.playbackState = .paused
    }
    
    @objc func playbackStopped(_ notification: Notification) {
        self.playPauseButton.image = NSImage(named: "Play")
        self.nowPlayingInfoCenter.playbackState = .stopped
    }
    
    @objc func togglePlayPauseCommandAction() -> MPRemoteCommandHandlerStatus {
        if self.player.playlistHasMedia() {
            self.playPause()
            return .success
        } else {
            return .noActionableNowPlayingItem
        }
    }
    
    @objc func playCommandAction() -> MPRemoteCommandHandlerStatus {
        if self.player.playlistHasMedia() {
            self.play()
            return .success
        } else {
            return .noActionableNowPlayingItem
        }
    }
    
    @objc func pauseCommandAction() -> MPRemoteCommandHandlerStatus {
        if self.player.playlistHasMedia() {
            self.pause()
            return .success
        } else {
            return .noActionableNowPlayingItem
        }
    }
    
    @objc func previousTrackCommandAction() -> MPRemoteCommandHandlerStatus {
        if self.player.playlistHasMedia() {
            self.player.previousTrack()
            return .success
        } else {
            return .noActionableNowPlayingItem
        }
    }
    
    @objc func nextTrackCommandAction() -> MPRemoteCommandHandlerStatus {
        if self.player.playlistHasMedia() {
            self.nextTrack()
            return .success
        } else {
            return .noActionableNowPlayingItem
        }
    }
    
    @objc func changePlaybackPositionCommandAction(_ sender: Any?) -> MPRemoteCommandHandlerStatus {
        if let sender = sender as? MPChangePlaybackPositionCommandEvent {
            self.newPlaybackPositionTime = sender.positionTime
            self.player.setPosition(position: self.newPlaybackPositionTime)
            updatePosition()
            return .success
        }
        return .commandFailed
    }
    
    @objc func playlistIndexesRemoved(_ sender: Any?) {
        if let sender = sender as AnyObject? {
            if let object = sender.object as? PlaylistOutlineView {
                var indexes: [Int] = []
                for index in object.removedIndexes {
                    indexes.append(index)
                }
                self.player.removeMedia(atIndexes: indexes)
            }
        }
    }
}
