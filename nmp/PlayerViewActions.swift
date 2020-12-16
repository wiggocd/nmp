//
//  ViewActions.swift
//  nmp
//
//  Created by C. Wiggins on 06/12/2020.
//  Copyright © 2020 C. Wiggins. All rights reserved.
//

import Foundation
import Cocoa

extension PlayerViewController {
    @IBAction func clearPlaylist(_ sender: Any) {
        player.clear()
        setUIDefaults()
    }
    
    @IBAction func openAction(_ sender: Any) {
        player.addMedia(urls: openMedia(), updateIndexIfNew: true, shouldPlay: true)
    }
    
    @IBAction func playlistAction(_ sender: Any) {
        if playlistScrollView.isHidden {
            NSAnimationContext.runAnimationGroup( { context in
                context.duration = 0.4
                playlistScrollView.alphaValue = 0
                self.playlistScrollView.isHidden = false
                playlistScrollView.animator().alphaValue = 1
                self.application?.userDefaults.set(false, forKey: "PlaylistHidden")
            })
        } else {
            NSAnimationContext.runAnimationGroup( { context in
                context.duration = 0.4
                playlistScrollView.animator().alphaValue = 0
            }) {
                self.playlistScrollView.isHidden = true
                self.application?.userDefaults.set(true, forKey: "PlaylistHidden")
            }
        }
    }
    
    @IBAction func playPauseAction(_ sender: Any) {
        playPause()
    }
    
    @IBAction func nextTrackAction(_ sender: Any) {
        nextTrack()
    }
    
    @IBAction func rewindAction(_ sender: Any) {
        rewind()
    }
    
    @IBAction func timeSliderMoved(_ sender: Any) {
        if let sender = sender as? NSSlider {
            player.setPosition(position: sender.doubleValue)
            positionLabel.stringValue = to_hhmmss(seconds: player.position)
        }
    }
    
    @IBAction func volumeSliderMoved(_ sender: Any) {
        if let sender = sender as? NSSlider {
            player.volume = sender.floatValue
            application?.userDefaults.set(sender.floatValue, forKey: "Volume")
        }
    }
    
    @IBAction func playlistOutlineViewDoubleAction(_ sender: Any) {
        if let sender = sender as? NSOutlineView {
            play(atIndex: sender.selectedRow)
        }
    }
}