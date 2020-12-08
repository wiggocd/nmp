//
//  ViewSelectors.swift
//  nmp
//
//  Created by Kate Wiggins on 06/12/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import AppKit

extension ViewController {
    @objc func updatePosition() {
        timeSlider.doubleValue = player.position()
        positionLabel.stringValue = to_hhmmss(seconds: player.position())
    }
    
    @objc func playlistChanged(_ notification: Notification) {
        createPlaylistItems(urls: player.playlist)
        playlistOutlineView.reloadData()
    }
    
    @objc func mediaChanged(_ notification: Notification) {
        if player.playlistHasMedia() {
            if player.metadata != nil {
                titleLabel.stringValue = player.metadata.title
                detailsLabel.stringValue = player.metadata.detailsString()
                if player.metadata.artwork != nil {
                    setCoverImage(image: player.metadata.artwork)
                    setBackgroundView()
                    playPauseButton.appearance = NSAppearance(named: .darkAqua)
                } else {
                    resetCoverImage()
                }
            }
        } else {
            setDefaultAppearances()
        }
        
        timeSlider.maxValue = player.duration()
        timeSlider.reset()
        positionLabel.stringValue = to_hhmmss(seconds: 0.0)
        durationLabel.stringValue = to_hhmmss(seconds: player.duration())
        startPositionTimer()
    }
    
    @objc func playbackStarted(_ notification: Notification) {
        playPauseButton.image = NSImage(named: "Pause")
    }
    
    @objc func playbackPaused(_ notification: Notification) {
        playPauseButton.image = NSImage(named: "Play")
    }
    
    @objc func playbackStopped(_ notification: Notification) {
        playPauseButton.image = NSImage(named: "Play")
    }
}
