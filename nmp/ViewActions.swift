//
//  ViewActions.swift
//  nmp
//
//  Created by Kate Wiggins on 06/12/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import Cocoa

extension ViewController {
    @IBAction func clearPlaylist(_ sender: Any) {
        player.clear()
        setUIDefaults()
    }
    
    @IBAction func openAction(_ sender: Any) {
        player.addMedia(urls: openMedia())
    }
    
    @IBAction func playlistAction(_ sender: Any) {
        if playlistScrollView.isHidden {
            NSAnimationContext.runAnimationGroup( { context in
                context.duration = 0.4
                playlistScrollView.animator().alphaValue = 0
                self.playlistScrollView.isHidden = false
                playlistScrollView.animator().alphaValue = 1
            })
        } else {
            NSAnimationContext.runAnimationGroup( { context in
                context.duration = 0.4
                playlistScrollView.animator().alphaValue = 0
            }) {
                self.playlistScrollView.isHidden = true
            }
        }
    }
    
    @IBAction func playPauseAction(_ sender: Any) {
        playPause()
    }
    
    @IBAction func nextTrackAction(_ sender: Any) {
        player.nextTrack()
    }
    
    @IBAction func previousTrackAction(_ sender: Any) {
        player.previousTrack()
    }
    
    @IBAction func timeSliderMoved(_ sender: Any) {
        player.setPosition(position: timeSlider.doubleValue)
        positionLabel.stringValue = to_hhmmss(seconds: player.position())
    }
    
    @IBAction func playlistOutlineViewDoubleAction(_ sender: Any) {
        if let sender = sender as? NSOutlineView {
            play(atIndex: sender.selectedRow)
        }
    }
}
