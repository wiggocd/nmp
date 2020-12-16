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
        setBackgroundView()
    }
    
    @objc func updatePosition() {
        timeSlider.doubleValue = player.position
        positionLabel.stringValue = to_hhmmss(seconds: player.position)
        nowPlayingInfoCenter.nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.position
    }
    
    @objc func playlistChanged(_ notification: Notification) {
        updatePlaylist()
    }
    
    @objc func mediaChanged(_ notification: Notification) {
        updateMedia()
    }
    
    @objc func playbackStarted(_ notification: Notification) {
        playPauseButton.image = NSImage(named: "Pause")
        nowPlayingInfoCenter.playbackState = .playing
    }
    
    @objc func playbackPaused(_ notification: Notification) {
        playPauseButton.image = NSImage(named: "Play")
        nowPlayingInfoCenter.playbackState = .paused
    }
    
    @objc func playbackStopped(_ notification: Notification) {
        playPauseButton.image = NSImage(named: "Play")
        nowPlayingInfoCenter.playbackState = .stopped
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
            player.setPosition(position: sender.positionTime)
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
                player.removeMedia(atIndexes: indexes)
            }
        }
    }
}
