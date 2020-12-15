//
//  ViewSelectors.swift
//  nmp
//
//  Created by C. Wiggins on 06/12/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import Cocoa

extension PlayerViewController {
    @objc func refresh() {
        setBackgroundView()
    }
    
    @objc func updatePosition() {
        timeSlider.doubleValue = player.position
        positionLabel.stringValue = to_hhmmss(seconds: player.position)
    }
    
    @objc func playlistChanged(_ notification: Notification) {
        updatePlaylist()
    }
    
    @objc func mediaChanged(_ notification: Notification) {
        updateMedia()
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
