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
        self.setBackgroundViewAndAppearance()
    }
    
    @objc func updatePosition() {
        self.timeSlider.doubleValue = self.player.position
        self.positionLabel.stringValue = to_hhmmss(seconds: self.player.position)
        if self.newPlaybackPositionTime != nil {
            self.player.position = self.newPlaybackPositionTime
            self.newPlaybackPositionTime = nil
        }
    }
    
    @objc func positionSet() {
        self.nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.player.position
    }
    
    @objc func rateChanged() {
        if self.player.currentURL != self.lastURL {
            self.updateNowPlayingInfoCenter()
        }
        self.lastURL = self.player.currentURL
    }
    
    @objc func updateNowPlayingInfoCenter() {
        // MARK: Todo - fix position incrementing whilst paused
        if self.player.hasMedia() {
            var dict: [String: Any] = [
                MPNowPlayingInfoPropertyPlaybackRate: self.player.rate,
                MPNowPlayingInfoPropertyElapsedPlaybackTime: self.player.position,
                MPMediaItemPropertyPlaybackDuration: self.player.duration
            ]
            
            if let metadata = self.player.metadata, let artwork = metadata.artwork {
                let coverArt = MPMediaItemArtwork(boundsSize: self.coverImageMinimumSize) { (size) -> NSImage in
                    return NSImage(cgImage: artwork, size: size)
                }
                
                dict[MPMediaItemPropertyArtwork] = coverArt
                dict[MPMediaItemPropertyTitle] = metadata.title
                dict[MPMediaItemPropertyArtist] = metadata.artist
                dict[MPMediaItemPropertyAlbumTitle] = metadata.album
            }
            
            self.nowPlayingInfoCenter.nowPlayingInfo = dict
        } else {
            self.nowPlayingInfoCenter.nowPlayingInfo = [:]
        }
    }
    
    @objc func playlistChanged(_ notification: Notification) {
        self.updatePlaylist()
    }
    
    @objc func mediaChanged(_ notification: Notification) {
        self.updateMedia()
    }
    
    @objc func playbackStarted(_ notification: Notification) {
        self.playPauseButton.image = NSImage(named: "Pause")
        self.nowPlayingInfoCenter.playbackState = .playing
        self.updateNowPlayingInfoCenter()
    }
    
    @objc func playbackPaused(_ notification: Notification) {
        self.playPauseButton.image = NSImage(named: "Play")
        self.nowPlayingInfoCenter.playbackState = .paused
        self.updateNowPlayingInfoCenter()
    }
    
    @objc func playbackStopped(_ notification: Notification) {
        self.playPauseButton.image = NSImage(named: "Play")
        self.nowPlayingInfoCenter.playbackState = .stopped
        self.updateNowPlayingInfoCenter()
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
            self.updatePosition()
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
